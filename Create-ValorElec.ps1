# ============================================================
# Script : Create-ValorElec.ps1
# Description : Création des utilisateurs ValorElec dans l'AD
#               + affectation aux groupes + export CSV
# Auteur : BTS SIO SISR - Atelier 2
# ============================================================

# --- Variables globales ---
$domaine     = "chasseneuil.local"
$ouBase      = "OU=ValorElec,OU=Entreprises,OU=TiersLieux86,DC=chasseneuil,DC=local"
$ouUsers     = "OU=Utilisateurs,$ouBase"
$ouGroupes   = "OU=Groupes globaux,$ouBase"
$mdp         = ConvertTo-SecureString "Azerty123!" -AsPlainText -Force
$exportPath  = "C:\ValorElec_Utilisateurs.csv"

# --- Liste des utilisateurs ---
# Format : Prenom, Nom, Service, Groupe
$utilisateurs = @(
    @{ Prenom="Thomas";      Nom="Bernard";    Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Julie";       Nom="Martin";     Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Kevin";       Nom="Dubois";     Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Sarah";       Nom="Leroy";      Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Nicolas";     Nom="Petit";      Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Emma";        Nom="Moreau";     Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Lucas";       Nom="Simon";      Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Chloe";       Nom="Laurent";    Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Maxime";      Nom="Michel";     Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Laura";       Nom="Garcia";     Service="Recherche et Developpement"; Groupe="GRP_RD" },
    @{ Prenom="Pierre";      Nom="Dupont";     Service="Commercial";                 Groupe="GRP_Commercial" },
    @{ Prenom="Jean";        Nom="Directeur";  Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Marie";       Nom="Dupont";     Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Paul";        Nom="Rousseau";   Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Sophie";      Nom="Bernard";    Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Marc";        Nom="Lefevre";    Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Anne";        Nom="Thomas";     Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Eric";        Nom="Martin";     Service="Direction";                  Groupe="GRP_Direction" },
    @{ Prenom="Directeur";   Nom="Commercial"; Service="Direction";                  Groupe="GRP_Direction" }
)

# --- Création des utilisateurs ---
Write-Host "=== Création des utilisateurs ValorElec ===" -ForegroundColor Cyan
$export = @()

foreach ($u in $utilisateurs) {
    $login      = "$($u.Prenom.ToLower()).$($u.Nom.ToLower())"
    $nomComplet = "$($u.Prenom) $($u.Nom)"
    $upn        = "$login@$domaine"

    try {
        New-ADUser `
            -Name              $nomComplet `
            -GivenName         $u.Prenom `
            -Surname           $u.Nom `
            -SamAccountName    $login `
            -UserPrincipalName $upn `
            -Path              $ouUsers `
            -AccountPassword   $mdp `
            -Enabled           $true `
            -PasswordNeverExpires $true `
            -DisplayName       $nomComplet `
            -Department        $u.Service

        Write-Host "  [OK] Utilisateur cree : $login" -ForegroundColor Green

        # Ajout au groupe
        $groupeDN = "CN=$($u.Groupe),$ouGroupes"
        Add-ADGroupMember -Identity $groupeDN -Members $login
        Write-Host "  [OK] Ajoute au groupe : $($u.Groupe)" -ForegroundColor Green

        # Ajout à l'export
        $export += [PSCustomObject]@{
            Prenom   = $u.Prenom
            Nom      = $u.Nom
            Login    = $login
            UPN      = $upn
            Service  = $u.Service
            Groupe   = $u.Groupe
            MotDePasse = "Azerty123!"
        }

    } catch {
        Write-Host "  [ERREUR] $login : $_" -ForegroundColor Red
    }
}

# --- Export CSV ---
$export | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host ""
Write-Host "=== Termine ! ===" -ForegroundColor Cyan
Write-Host "Fichier CSV exporte : $exportPath" -ForegroundColor Yellow
Write-Host "Total utilisateurs crees : $($export.Count)" -ForegroundColor Yellow
