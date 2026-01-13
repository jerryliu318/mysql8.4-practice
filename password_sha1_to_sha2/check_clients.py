import mysql.connector
from mysql.connector import Error
import time
import sys

def test_connection(user, password, description):
    print(f"\n[{description}] Testing connection for user: '{user}'")
    try:
        connection = mysql.connector.connect(
            host='mysql_server',
            database='demo_db',
            user=user,
            password=password,
            connection_timeout=5
        )
        if connection.is_connected():
            db_info = connection.get_server_info()
            print(f"✅ SUCCESS: Connected to MySQL Server version {db_info}")
            
            cursor = connection.cursor()
            cursor.execute("SELECT content FROM messages;")
            record = cursor.fetchone()
            print(f"   Data retrieved: {record[0]}")
            
            cursor.close()
            connection.close()
            return True
    except Error as e:
        print(f"❌ FAILED: Error while connecting: {e}")
        return False
    return False

if __name__ == "__main__":
    print("--- Starting Connectivity Checks ---")
    
    # Simple retry loop to wait for DB readiness
    time.sleep(2) 

    # Test SHA1 (Native) - The one expected to fail after upgrade without config
    success_sha1 = test_connection('user_sha1', 'password_sha1', 'Legacy Client (SHA1 / mysql_native_password)')
    
    # Test SHA2 (Caching) - The one expected to work seamlessly throughout
    success_sha2 = test_connection('user_sha2', 'password_sha2', 'Modern Client (SHA2 / caching_sha2_password)')

    print("\n" + "="*40)
    print("           UPGRADE ANALYSIS           ")
    print("="*40)
    
    if success_sha1:
        print("🔹 SHA1 User:  WORKING (Legacy Support Active)")
    else:
        print("❌ SHA1 User:  FAILED (Needs --mysql-native-password=ON)")

    if success_sha2:
        print("✅ SHA2 User:  WORKING (Seamless Transition!)")
    else:
        print("❌ SHA2 User:  FAILED (Unexpected error)")
    print("="*40)

    if success_sha1 and success_sha2:
        print("\n🎉 All checks PASSED! Both legacy and modern clients can connect.")
    elif success_sha2:
        print("\n⚠️  NOTICE: Modern (SHA2) client is fine, but Legacy (SHA1) is blocked.")
