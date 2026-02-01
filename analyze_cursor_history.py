import sqlite3
import json
import os

db_path = os.path.expanduser('~\\AppData\\Roaming\\Cursor\\User\\globalStorage\\state.vscdb')

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Try to find the recent paths key
    cursor.execute("SELECT key, value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'")
    row = cursor.fetchone()
    
    if row:
        print("Found recent paths:")
        value = row[1]
        try:
            data = json.loads(value)
            # Structure is usually {"entries": [{"folderUri": "file:///..."}, ...]}
            if 'entries' in data:
                print(f"Number of entries: {len(data['entries'])}")
                for entry in data['entries']:
                    if 'folderUri' in entry:
                        print(f"Folder: {entry['folderUri']}")
                    elif 'fileUri' in entry:
                        print(f"File: {entry['fileUri']}")
                    elif 'workspace' in entry:
                        print(f"Workspace: {entry['workspace']}")
                    else:
                        print(f"Unknown entry: {entry}")
            else:
                print("No 'entries' key found in JSON.")
                print(json.dumps(data, indent=2))
        except json.JSONDecodeError:
            print("Could not decode JSON value")
            print(value)
    else:
        print("Key 'history.recentlyOpenedPathsList' not found.")
        # List some keys to help debug
        print("Listing first 10 keys:")
        cursor.execute("SELECT key FROM ItemTable LIMIT 10")
        for r in cursor.fetchall():
            print(r[0])

    conn.close()

except Exception as e:
    print(f"Error: {e}")
