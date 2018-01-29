#####################################################################
#
# SQL Serverのリストアをぶん回すスクリプト
#
#####################################################################

# スクリプトPATH
$Basedir = Split-Path -Path $MyInvocation.InvocationName -Parent

# 対象スキーマリスト
$Schema_list = "$Basedir\restore_red.txt"

# Distinationインスタンスのディレクトリ
$Server = "localhost,1433"
$dist_dbdir = "C:\database\data"
$dist_logdir = "C:\database\log"
$dist_backup = "C:\database\backup"


#####################################################################
#
# バックアップファイルの取得
#
#####################################################################

$dbname_dict = @{}
foreach ($dbline in Get-Content $Schema_list) {
    $dbname = ($dbline.split(","))[0]
    $SourceDir = ($dbline.split(","))[1]
    $bk_path = "$SourceDir\$dbname"
    if ( (Test-Path $bk_path) -eq "True" ){ 
        $file = Get-ChildItem $bk_path | sort | Select -Last 1 | % {$_.Name}
    }
    $dbname_dict.$dbname = "$bk_path\$file"

}

$dbname_dict

#####################################################################
#
# リストアコマンドの生成（辞書）
#
#####################################################################

$command = @{}
foreach ($key in $dbname_dict.keys) {
    
    $backup_file = $dbname_dict[$key]
    $sql = "RESTORE FILELISTONLY FROM DISK = `'$backup_file`'"
    $result = Invoke-command -ScriptBlock { Invoke-sqlcmd -ServerInstance $args[0] -Query $args[1] } -ArgumentList $Server,$sql
    $data_name = $result | Select PhysicalName,LogicalName
    
    $move_tmp = @();
    foreach ($file in $data_name){          
        $pysfile = (($file.PhysicalName).split("\"))[-1]
        $logfile = (($file.LogicalName).split("\"))[-1]
        
        if ($pysfile -like "*ldf"){
            $result_file = ( $dist_logdir + "\" + $pysfile )
            $move_tmp += "MOVE `'$logfile`' TO `'$result_file`', "
            
        }elseif (($pysfile -like "*mdf") -Or ($pysfile -like "*ndf") -Or ($pysfile -like "*log")){
            $result_file = ( $dist_dbdir + "\" + $pysfile )
            $move_tmp += "MOVE `'$logfile`' TO `'$result_file`', "
        }
    }
        
    $move_cmd = ($move_tmp -join(" ")) -replace(", $","")
               
    $sql = "RESTORE DATABASE [$key] FROM DISK = `'$backup_file`' WITH STANDBY = N`'$dist_backup\$key.BAK`', REPLACE , $move_cmd"
    Invoke-command -ScriptBlock { Invoke-sqlcmd -QueryTimeout 86400 -ServerInstance $args[0] -Query $args[1] } -ArgumentList $Server,$sql
    write-output("$sql")
}
