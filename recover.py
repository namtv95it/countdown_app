import json
import os

transcript_path = r"C:\Users\namtv\.gemini\antigravity-ide\brain\a5849ddc-0fc8-4541-8b18-b2ad86cc7df9\.system_generated\logs\transcript_full.jsonl"
edit_screen_content = ""
dashboard_content = ""

for line in open(transcript_path, 'r', encoding='utf-8'):
    try:
        data = json.loads(line)
        if data.get('type') == 'PLANNER_RESPONSE' and 'tool_calls' in data:
            for call in data['tool_calls']:
                if call['name'] == 'write_to_file':
                    args = call.get('args', {})
                    if 'admin_edit_gift_screen.dart' in args.get('TargetFile', ''):
                        edit_screen_content = args.get('CodeContent', '')
                    if 'admin_gift_dashboard.dart' in args.get('TargetFile', ''):
                        dashboard_content = args.get('CodeContent', '')
                elif call['name'] == 'replace_file_content' or call['name'] == 'multi_replace_file_content':
                    # We might need to apply the replacements, but let's just grab the last write_to_file first
                    pass
    except:
        pass

if edit_screen_content:
    with open(r"d:\Git\countdown_app\lib\screens\admin\admin_edit_gift_screen.dart", 'w', encoding='utf-8') as f:
        f.write(edit_screen_content)
    print("Recovered admin_edit_gift_screen.dart (initial version)")
        
if dashboard_content:
    with open(r"d:\Git\countdown_app\lib\screens\admin\admin_gift_dashboard.dart", 'w', encoding='utf-8') as f:
        f.write(dashboard_content)
    print("Recovered admin_gift_dashboard.dart (initial version)")
