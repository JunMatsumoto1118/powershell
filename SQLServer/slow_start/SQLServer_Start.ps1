###
#
# SQLServerを、iSCSIの接続後に起動するバッチ
# サービスの起動遅延よりも遅い時に使う
#
###

# 変数
$SRV   = 'MSSQL*'
$AGT   = 'SQLSERVERAGENT*'
$CHECK_PATH = 'G:\iscsi.txt'
$DATE = Get-Date
$SLEEP = 60

# サーバー起動後、x秒待つ
sleep $SLEEP

# SQLSERVERのServiceNameを取得
$SERVNAME = Get-Service | ? {$_.Name -like ${SRV}} | ? {$_.Status -eq 'Stopped'} | % Name


# SQLSERVERAGENTのServiceNameを取得
$SERVAGENT = Get-Service | ? {$_.Name -like ${AGT}} | ? {$_.Status -eq 'Stopped'} | % Name


# ISCSIが動いているか確認
try{
    # iSCSIドライブにデータを入れる
    Add-Content $CHECK_PATH $DATE

    # データが書き込めたらドライブが正常と判断し、SQLServerを起動
    if (($? -eq $True) -and ($SERVNAME.count -ge 1)) {
        Foreach ($s in $SERVNAME) {
            Start-Service $s
        }
    }
    # SQLServerAgentを起動
    if ($SERVAGENT.count -ge 1) {
        Foreach ($a in $SERVAGENT) {
            Start-Service $a
        }
    }
}catch{
    pass
    }

# 後処理
Remove-Item $CHECK_PATH