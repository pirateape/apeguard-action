# ApeGuard Demo GIF
# Generated with: vhs < demo.tape
# Install vhs: brew install vhs

Output apeguard-demo.gif

Set FontSize 14
Set Theme "Dracula"
Set Width 800
Set Height 400
Set Padding 32
Set Framerate 15

Type "cd /tmp/demo-target" Sleep 300ms
Enter
Sleep 500ms

# Show version
Type "apeguard version" Sleep 500ms
Enter
Sleep 1s

# Show what we're about to scan
Type "ls -la" Sleep 300ms
Enter
Sleep 1s

# Run the scan
Type "apeguard scan --quiet" Sleep 500ms
Enter
Sleep 4s

# Show the scorecard
Type "cat .apeguard/reports/apeguard-report.json | python3 -m json.tool | head -30" Sleep 300ms
Enter
Sleep 2s
