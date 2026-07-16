@echo off
chcp 65001 >nul
powershell -NoProfile -Command "Get-Content -Raw -Encoding UTF8 '%~dp0CRISPE卡牌配對-GoogleSites嵌入用.html' | Set-Clipboard"
echo.
echo 已複製到剪貼簿！
echo 請到 Google 協作平台編輯畫面，插入 -^> 嵌入 -^> 嵌入程式碼，
echo 按 Ctrl+V 貼上，並把嵌入框拉高（建議至少 900px）再發布。
echo.
pause
