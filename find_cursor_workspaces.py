import os
import json
import datetime

workspace_storage_path = os.path.expanduser('~\\AppData\\Roaming\\Cursor\\User\\workspaceStorage')

if not os.path.exists(workspace_storage_path):
    print(f"Path not found: {workspace_storage_path}")
    exit(1)

workspaces = []

for folder_name in os.listdir(workspace_storage_path):
    folder_path = os.path.join(workspace_storage_path, folder_name)
    if os.path.isdir(folder_path):
        json_path = os.path.join(folder_path, 'workspace.json')
        if os.path.exists(json_path):
            try:
                # Get modification time
                mod_time = os.path.getmtime(json_path)
                
                with open(json_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    # Structure usually has 'folder' or 'workspace'
                    path = None
                    if 'folder' in data:
                        path = data['folder']
                    elif 'configuration' in data:
                         path = data['configuration']
                    
                    if path:
                        workspaces.append({
                            'path': path,
                            'time': mod_time,
                            'id': folder_name
                        })
            except Exception as e:
                pass

# Sort by time descending
workspaces.sort(key=lambda x: x['time'], reverse=True)

print(f"Found {len(workspaces)} workspaces. Top 5 most recent:")
for ws in workspaces[:5]:
    dt = datetime.datetime.fromtimestamp(ws['time']).strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{dt}] {ws['path']}")
