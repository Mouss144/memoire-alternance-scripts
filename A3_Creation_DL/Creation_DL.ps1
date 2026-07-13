Connect-ExchangeOnline

$groups = @(
    @{Name="Casablanca ADQ FIM AIP"; Email="casablanca.adq_fim_aip@sia-partners.com"},
    @{Name="Lille ADQ FIM AIP"; Email="lille.adq_fim_aip@sia-partners.com"},
    @{Name="Luxembourg ADQ FIM AIP"; Email="luxembourg.adq_fim_aip@sia-partners.com"},
    @{Name="Lyon ADQ FIM AIP"; Email="lyon.adq_fim_aip@sia-partners.com"},
    @{Name="Marseille ADQ FIM AIP"; Email="marseille.adq_fim_aip@sia-partners.com"},
    @{Name="Milan ADQ FIM AIP"; Email="milan.adq_fim_aip@sia-partners.com"},
    @{Name="Nantes ADQ FIM AIP"; Email="nantes.adq_fim_aip@sia-partners.com"},
    @{Name="Paris ADQ FIM AIP"; Email="paris.adq_fim_aip@sia-partners.com"},
    @{Name="Rome ADQ FIM AIP"; Email="rome.adq_fim_aip@sia-partners.com"},
    @{Name="Morocco ADQ FIM AIP"; Email="morocco.adq_fim_aip@sia-partners.com"},
    @{Name="France ADQ FIM AIP"; Email="france.adq_fim_aip@sia-partners.com"},
    @{Name="Italy ADQ FIM AIP"; Email="italy.adq_fim_aip@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Manager"; Email="adq_fim_aip.seniormanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Administration"; Email="adq_fim_aip.administration@sia-partners.com"},
    @{Name="ADQ FIM AIP Associate Manager"; Email="adq_fim_aip.associatemanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Intern"; Email="adq_fim_aip.intern@sia-partners.com"},
    @{Name="ADQ FIM AIP Consultant"; Email="adq_fim_aip.consultant@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Engagement Manager"; Email="adq_fim_aip.seniorengagementmanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Consultant"; Email="adq_fim_aip.seniorconsultant@sia-partners.com"},
    @{Name="ADQ FIM AIP Associate Consultant"; Email="adq_fim_aip.associateconsultant@sia-partners.com"},
    @{Name="ADQ FIM AIP Subject Matter Expert"; Email="adq_fim_aip.subjectmatterexpert@sia-partners.com"},
    @{Name="ADQ FIM AIP Engagement Manager"; Email="adq_fim_aip.engagementmanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Manager"; Email="adq_fim_aip.manager@sia-partners.com"},
    @{Name="ADQ FIM AIP Associate Partner"; Email="adq_fim_aip.associatepartner@sia-partners.com"},
    @{Name="ADQ FIM AIP VIE"; Email="adq_fim_aip.vie@sia-partners.com"},
    @{Name="ADQ FIM AIP Partner"; Email="adq_fim_aip.partner@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Industry Expert"; Email="adq_fim_aip.seniorindustryexpert@sia-partners.com"},
    @{Name="ADQ FIM AIP Managing Director"; Email="adq_fim_aip.managingdirector@sia-partners.com"},
    @{Name="ADQ FIM AIP Engagement Director"; Email="adq_fim_aip.engagementdirector@sia-partners.com"},
    @{Name="ADQ FIM AIP Industry Expert"; Email="adq_fim_aip.industryexpert@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Advisor"; Email="adq_fim_aip.senioradvisor@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior SME"; Email="adq_fim_aip.seniorsme@sia-partners.com"},
    @{Name="ADQ FIM AIP IT"; Email="adq_fim_aip.it@sia-partners.com"},
    @{Name="ADQ FIM AIP Engineering Manager"; Email="adq_fim_aip.engineeringmanager@sia-partners.com"},
    @{Name="ADQ FIM AIP SME Manager"; Email="adq_fim_aip.smemanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Engineering Manager"; Email="adq_fim_aip.seniorengineeringmanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Project Director"; Email="adq_fim_aip.projectdirector@sia-partners.com"},
    @{Name="ADQ FIM AIP Contractor"; Email="adq_fim_aip.contractor@sia-partners.com"},
    @{Name="ADQ FIM AIP Analyst"; Email="adq_fim_aip.analyst@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Design Director"; Email="adq_fim_aip.seniordesigndirector@sia-partners.com"},
    @{Name="ADQ FIM AIP SME Director"; Email="adq_fim_aip.smedirector@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Engagement Manager Alt"; Email="adq_fim_aip.seniorengagmentmanager@sia-partners.com"},
    @{Name="ADQ FIM AIP Senior Strategist"; Email="adq_fim_aip.seniorstrategist@sia-partners.com"}
)

foreach ($group in $groups) {
    $alias = ($group.Email.Split('@')[0] -replace '\.', '_')
    
    try {
        New-DistributionGroup `
            -Name $group.Name `
            -PrimarySmtpAddress $group.Email `
            -Alias $alias
        
        Write-Host " $($group.Name)" -ForegroundColor Green
    }
    catch {
        Write-Warning " $($group.Name) : $($_.Exception.Message)"
    }
}