function New-NinjaOnePUTRequest {
    <#
        .SYNOPSIS
            Builds a request for the NinjaOne API.
        .DESCRIPTION
            Wrapper function to build web requests for the NinjaOne API.
        .EXAMPLE
            PS C:\> New-NinjaOnePUTRequest -Resource "/v2/organizations -Body @{"name"="MyOrg"}
        .OUTPUTS
            Outputs an object containing the response from the web request.
    #>
    [CmdletBinding()]
    [OutputType([Object])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Private function - no need to support.')]
    param (
        # The resource to send the request to.
        [Parameter(Mandatory = $True)]
        [String]$Resource,
        # A hashtable used to build the query string.
        [HashTable]$QSCollection,
        # A hashtable used to build the body of the request.
        [Parameter(Mandatory = $True)]
        [Hashtable]$Body,
        # Force body to an array.
        [Switch]$AsArray
    )
    if ($null -eq $Script:NRAPIConnectionInformation) {
        Throw "Missing NinjaOne connection information, please run 'Connect-NinjaOne' first."
    }
    if ($null -eq $Script:NRAPIAuthenticationInformation) {
        Throw "Missing NinjaOne authentication tokens, please run 'Connect-NinjaOne' first."
    }
    try {
        if ($QSCollection) {
            Write-Debug "Query string in New-NinjaOnePUTRequest contains: $($QSCollection | Out-String)"
            $QueryStringCollection = [System.Web.HTTPUtility]::ParseQueryString([String]::Empty)
            Write-Verbose 'Building [HttpQSCollection] for New-NinjaOnePUTRequest'
            foreach ($Key in $QSCollection.Keys) {
                $QueryStringCollection.Add($Key, $QSCollection.$Key)
            }
        } else {
            Write-Debug 'Query string collection not present...'
        }
        Write-Debug "URI is $($Script:NRAPIConnectionInformation.URL)"
        $RequestUri = [System.UriBuilder]"$($Script:NRAPIConnectionInformation.URL)"
        Write-Debug "Path is $($Resource)"
        $RequestUri.Path = $Resource
        if ($QueryStringCollection) {
            Write-Debug "Query string is $($QueryStringCollection | Out-String)"
            $RequestUri.Query = $QueryStringCollection
        } else {
            Write-Debug 'Query string not present...'
        }
        $WebRequestParams = @{
            Method = 'PUT'
            Uri = $RequestUri.ToString()
        }
        if ($Body) {
            Write-Verbose 'Building [HttpBody] for New-NinjaOnePUTRequest'
            $WebRequestParams.Body = ($Body | ConvertTo-Json -Depth 100 -AsArray:$AsArray)
            Write-Debug "Raw body is $($WebRequestParams.Body)"
        } else {
            Write-Verbose 'No body provided for New-NinjaOnePUTRequest'
        }
        Write-Debug "Building new NinjaOneRequest with params: $($WebRequestParams | Out-String)"
        try {
            $Result = Invoke-NinjaOneRequest -WebRequestParams $WebRequestParams
            Write-Debug "NinjaOne request returned $($Result | Out-String)"
            if ($Result['results']) {
                Return $Result.results
            } elseif ($Result['result']) {
                Return $Result.result
            } else {
                Return $Result
            }
        } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            throw $_
        } catch {
            New-NinjaOneError -ErrorRecord $_
        }
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        throw $_
    } catch {
        New-NinjaOneError -ErrorRecord $_
    }
}