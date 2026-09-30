param(
 [ValidateSet('inspect','publish','verify','docs','merge-docs')][string]$Mode='inspect',
 [string]$Source,
 [int]$PullRequest=0
)
$ErrorActionPreference='Stop'
$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
Set-Location $repoRoot
$version=(Get-Content VERSION -Raw).Trim()
$tag="v$version-test"
$base='https://api.github.com/repos/UnKami/Overkill'
$credentialLines="protocol=https`nhost=github.com`n`n" | git credential fill
$credential=@{}
foreach($line in $credentialLines){$pair=$line -split '=',2;if($pair.Count -eq 2){$credential[$pair[0]]=$pair[1]}}
if(!$credential['password']){throw 'GitHub authentication unavailable'}
$headers=@{Authorization=('Bearer '+$credential['password']);Accept='application/vnd.github+json';'User-Agent'='Overkill-release';'X-GitHub-Api-Version'='2022-11-28'}
function Api([string]$Path,[string]$Method='Get',$Body=$null) {
 $params=@{Uri=("$base"+$Path);Headers=$headers;Method=$Method}
 if($null -ne $Body){$params.Body=($Body | ConvertTo-Json -Depth 12 -Compress);$params.ContentType='application/json; charset=utf-8'}
 Invoke-RestMethod @params
}
$assets=@("installer/OverkillSetup-$version.exe","build/Overkill-$version-Windows.zip","installer/OverkillSetup-$version.sha256")
$notesPath='docs/encounter-{0:000}.md' -f ([version]$version).Minor
$docPaths=@('README.md','installer/README.md','UPDATE_LOG.md',$notesPath)
if($Mode -eq 'inspect'){
 $repo=Api ''
 $releases=Api '/releases?per_page=5'
 [pscustomobject]@{repository=$repo.full_name;can_push=$repo.permissions.push;default_branch=$repo.default_branch;tags=@($releases.tag_name)} | ConvertTo-Json
 exit
}
if($Mode -in @('publish','verify')){
 if($Source -notmatch '^[a-f0-9]{40}$'){throw 'Exact source SHA required'}
 if($Mode -eq 'publish'){
  $existing=@(Api '/releases?per_page=100' | Where-Object tag_name -eq $tag)
  if($existing.Count){throw 'Release already exists; never overwrite a published build'}
  $release=Api '/releases' 'Post' @{tag_name=$tag;target_commitish=$Source;name="Overkill $version - Crystalline continuity";body=((Get-Content $notesPath -Raw)+"`n`nSource: "+$Source+"`n`n"+(Get-Content '.test-artifacts/verification-031.md' -Raw));draft=$true;prerelease=$true}
  foreach($path in $assets){
   $file=Get-Item -LiteralPath $path
   $upload="https://uploads.github.com/repos/UnKami/Overkill/releases/$($release.id)/assets?name="+[uri]::EscapeDataString($file.Name)
   $asset=Invoke-RestMethod -Uri $upload -Headers $headers -Method Post -InFile $file.FullName -ContentType 'application/octet-stream' -TimeoutSec 1800
   if($asset.size -ne $file.Length){throw "Upload size mismatch: $path"}
   $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
   if($asset.digest -ne "sha256:$hash"){throw "Upload digest mismatch: $path"}
   Write-Output "UPLOADED_AND_HASHED $($file.Name)"
  }
  $release=Api "/releases/$($release.id)"
  if(@($release.assets).Count -ne 3 -or $release.target_commitish -ne $Source){throw 'Draft metadata mismatch'}
  $release=Api "/releases/$($release.id)" 'Patch' @{draft=$false}
 }
 $release=Api "/releases/tags/$tag"
 if($release.draft -or !$release.prerelease -or $release.target_commitish -ne $Source){throw 'Published source or release-state mismatch'}
 if(@($release.assets).Count -ne 3){throw 'Wrong asset count'}
 foreach($asset in $release.assets){
  $path=$assets | Where-Object {(Split-Path $_ -Leaf) -eq $asset.name} | Select-Object -First 1
  $file=Get-Item -LiteralPath $path
  $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if($asset.size -ne $file.Length -or $asset.digest -ne "sha256:$hash"){throw "Published digest mismatch: $path"}
  $response=Invoke-WebRequest -Uri $asset.browser_download_url -Method Head -MaximumRedirection 10
  if($response.StatusCode -ne 200){throw 'Public download unavailable'}
  Write-Output "PUBLIC_VERIFIED $($asset.name) $($asset.size) $hash"
 }
 Write-Output "RELEASE_OK $($release.html_url)"
 exit
}
if($Mode -eq 'docs'){
 $published=Api "/releases/tags/$tag"
 if($published.draft){throw 'Publish downloads first'}
 $main=Api '/git/ref/heads/main'
 $mainCommit=Api "/git/commits/$($main.object.sha)"
 $tree=@()
 foreach($path in $docPaths){
  $blob=Api '/git/blobs' 'Post' @{content=[Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $repoRoot $path)));encoding='base64'}
  $tree+=@{path=$path;mode='100644';type='blob';sha=$blob.sha}
 }
 $newTree=Api '/git/trees' 'Post' @{base_tree=$mainCommit.tree.sha;tree=$tree}
 $commit=Api '/git/commits' 'Post' @{message="docs: publish verified $version playtest downloads";tree=$newTree.sha;parents=@($main.object.sha)}
 $branch="fix/yonatan-031-downloads"
 $null=Api '/git/refs' 'Post' @{ref="refs/heads/$branch";sha=$commit.sha}
 $pr=Api '/pulls' 'Post' @{title="Publish verified $version crystalline playtest downloads";head=$branch;base='main';body="Documentation only: installer/portable links, exact source, verification and known limits. Gameplay remains on fix/yonatan-full-ui-polish. No gameplay merge is included."}
 Write-Output "DOCS_PR $($pr.number) $($pr.html_url) $($commit.sha)"
 exit
}
if($Mode -eq 'merge-docs'){
 if($PullRequest -le 0){throw 'PR number required after review'}
 $pr=Api "/pulls/$PullRequest"
 $files=@(Api "/pulls/$PullRequest/files")
 if($files.Count -ne $docPaths.Count -or $pr.base.ref -ne 'main'){throw 'Unexpected documentation PR scope'}
 foreach($file in $files){
  if($file.filename -notin $docPaths){throw 'Non-documentation change; merge blocked'}
  $remote=Api ("/contents/"+$file.filename+"?ref="+$pr.head.sha)
  $localBytes=[IO.File]::ReadAllBytes((Join-Path $repoRoot $file.filename))
  if($remote.content.Replace("`n","").Replace("`r","") -ne [Convert]::ToBase64String($localBytes)){throw 'PR content changed since local review'}
 }
 $merged=Api "/pulls/$PullRequest/merge" 'Put' @{sha=$pr.head.sha;merge_method='squash';commit_title="docs: publish verified $version downloads"}
 if(!$merged.merged){throw 'Documentation merge failed'}
 foreach($path in $docPaths){
  $remote=Api ("/contents/"+$path+"?ref=main")
  $body=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($remote.content))
  if(!$body.Contains($version)){throw "Current download version missing on main: $path"}
  Write-Output "MAIN_VERIFIED $path"
 }
 Write-Output "DOCS_MERGED $($pr.html_url) $($merged.sha)"
}

