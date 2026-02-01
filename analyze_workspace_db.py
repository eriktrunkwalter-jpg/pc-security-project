import sqlite3
import os

db_path = os.path.expanduser('~\\AppData\\Roaming\\Cursor\\User\\workspaceStorage\\1769894422899\\state.vscdb')

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Try to find any keys that look like paths
    cursor.execute("SELECT key, value FROM ItemTable WHERE key = 'memento/workbench.editors.files.textFileEditor'")
    for row in cursor.fetchall():
        key, value = row
        print(f"Key: {key}")
        print(f"Value: {value}")

    conn.close()

except Exception as e:
    print(f"Error: {e}")
