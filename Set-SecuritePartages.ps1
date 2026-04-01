# ============================================================
# Script : Set-SecuritePartages.ps1
# Description : Automatisation de la sécurité sur les partages
#               ValorElec - Atelier 2 Mission 3
#               Création des groupes domaine locaux (DL)
#               Affectation des groupes globaux dans les DL
#               Application des droits NTFS et partage
# Auteur : BTS SIO SISR - Atelier 2
# ============================================================

# --- Variables globales ---
$domaine   = "chasseneuil.local"
$ouGroupes = "OU=Groupes domaine locaux,OU=Groupes,OU=TiersLieux86,DC=chasseneuil,DC=local"
$chemins   = @{
    "RD"         = "E:\RD"
    "Commercial" = "E:\Commercial"
    "Direction"  = "E:\Direction"
}

Write-Host "=== Mise en place de la sécurité sur les partages ValorElec ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# ETAPE 1 : Création des groupes domaine locaux (DL)
# ============================================================
Write-Host "--- Etape 1 : Création des groupes domaine locaux ---" -ForegroundColor Yellow

$groupesDL = @(
    "DL_RD_Lecture",
    "DL_RD_Modification",
    "DL_RD_CtrlTotal",
    "DL_Com_Lecture",
    "DL_Com_Modification",
    "DL_Com_CtrlTotal",
    "DL_Dir_Lecture",
    "DL_Dir_Modification",
    "DL_Dir_CtrlTotal"
)

foreach ($dl in $groupesDL) {
    try {
        New-ADGroup `
            -Name          $dl `
            -GroupScope    DomainLocal `
            -GroupCategory Security `
            -Path          $ouGroupes `
            -Description   "Groupe domaine local - Sécurité partages ValorElec"
        Write-Host "  [OK] Groupe DL créé : $dl" -ForegroundColor Green
    } catch {
        Write-Host "  [INFO] $dl existe déjà ou erreur : $_" -ForegroundColor Gray
    }
}

Write-Host ""

# ============================================================
# ETAPE 2 : Affectation des groupes globaux dans les DL
# Modèle AGDLP : GG -> DL -> Permission
# ============================================================
Write-Host "--- Etape 2 : Affectation des groupes globaux dans les DL ---" -ForegroundColor Yellow

$affectations = @(
    @{ GG = "GRP_RD";         DL = "DL_RD_Modification" },
    @{ GG = "GRP_Commercial"; DL = "DL_Com_Modification" },
    @{ GG = "GRP_Direction";  DL = "DL_Dir_Modification" }
)

foreach ($a in $affectations) {
    try {
        Add-ADGroupMember -Identity $a.DL -Members $a.GG
        Write-Host "  [OK] $($a.GG) ajouté dans $($a.DL)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERREUR] $($a.GG) -> $($a.DL) : $_" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# ETAPE 3 : Application des droits NTFS
# ============================================================
Write-Host "--- Etape 3 : Application des droits NTFS ---" -ForegroundColor Yellow

$droitsNTFS = @(
    @{ Chemin = "E:\RD";         Groupe = "CHASSENEUIL\DL_RD_Modification";  Droit = "Modify" },
    @{ Chemin = "E:\RD";         Groupe = "CHASSENEUIL\DL_RD_Lecture";       Droit = "ReadAndExecute" },
    @{ Chemin = "E:\RD";         Groupe = "CHASSENEUIL\DL_RD_CtrlTotal";     Droit = "FullControl" },
    @{ Chemin = "E:\Commercial"; Groupe = "CHASSENEUIL\DL_Com_Modification"; Droit = "Modify" },
    @{ Chemin = "E:\Commercial"; Groupe = "CHASSENEUIL\DL_Com_Lecture";      Droit = "ReadAndExecute" },
    @{ Chemin = "E:\Commercial"; Groupe = "CHASSENEUIL\DL_Com_CtrlTotal";    Droit = "FullControl" },
    @{ Chemin = "E:\Direction";  Groupe = "CHASSENEUIL\DL_Dir_Modification"; Droit = "Modify" },
    @{ Chemin = "E:\Direction";  Groupe = "CHASSENEUIL\DL_Dir_Lecture";      Droit = "ReadAndExecute" },
    @{ Chemin = "E:\Direction";  Groupe = "CHASSENEUIL\DL_Dir_CtrlTotal";    Droit = "FullControl" }
)

foreach ($d in $droitsNTFS) {
    try {
        $acl  = Get-Acl $d.Chemin
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $d.Groupe,
            $d.Droit,
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl $d.Chemin $acl
        Write-Host "  [OK] NTFS $($d.Droit) appliqué sur $($d.Chemin) pour $($d.Groupe)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERREUR] $($d.Chemin) - $($d.Groupe) : $_" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# ETAPE 4 : Application des droits de partage SMB
# ============================================================
Write-Host "--- Etape 4 : Mise à jour des droits de partage SMB ---" -ForegroundColor Yellow

$droitsSMB = @(
    @{ Partage = "RD";         Groupe = "CHASSENEUIL\DL_RD_Modification";  Acces = "Change" },
    @{ Partage = "RD";         Groupe = "CHASSENEUIL\DL_RD_Lecture";       Acces = "Read" },
    @{ Partage = "RD";         Groupe = "CHASSENEUIL\DL_RD_CtrlTotal";     Acces = "Full" },
    @{ Partage = "Commercial"; Groupe = "CHASSENEUIL\DL_Com_Modification"; Acces = "Change" },
    @{ Partage = "Commercial"; Groupe = "CHASSENEUIL\DL_Com_Lecture";      Acces = "Read" },
    @{ Partage = "Commercial"; Groupe = "CHASSENEUIL\DL_Com_CtrlTotal";    Acces = "Full" },
    @{ Partage = "Direction";  Groupe = "CHASSENEUIL\DL_Dir_Modification"; Acces = "Change" },
    @{ Partage = "Direction";  Groupe = "CHASSENEUIL\DL_Dir_Lecture";      Acces = "Read" },
    @{ Partage = "Direction";  Groupe = "CHASSENEUIL\DL_Dir_CtrlTotal";    Acces = "Full" }
)

foreach ($s in $droitsSMB) {
    try {
        if ($s.Acces -eq "Full") {
            Grant-SmbShareAccess -Name $s.Partage -AccountName $s.Groupe -AccessRight Full -Force
        } elseif ($s.Acces -eq "Change") {
            Grant-SmbShareAccess -Name $s.Partage -AccountName $s.Groupe -AccessRight Change -Force
        } else {
            Grant-SmbShareAccess -Name $s.Partage -AccountName $s.Groupe -AccessRight Read -Force
        }
        Write-Host "  [OK] SMB $($s.Acces) appliqué sur \\$($s.Partage) pour $($s.Groupe)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERREUR] $($s.Partage) - $($s.Groupe) : $_" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# VERIFICATION FINALE
# ============================================================
Write-Host "--- Vérification finale ---" -ForegroundColor Yellow

foreach ($partage in @("RD", "Commercial", "Direction")) {
    Write-Host "  Partage : $partage" -ForegroundColor Cyan
    Get-SmbShareAccess -Name $partage | Format-Table AccountName, AccessRight -AutoSize
}

Write-Host "=== Script terminé avec succès ===" -ForegroundColor Cyan
