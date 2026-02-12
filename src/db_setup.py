#!/usr/bin/env python3
"""
Database Setup Automation
Auto-create Supabase tables, indexes, and functions
"""

import json
from pathlib import Path
from typing import Dict
from supabase import create_client


class DatabaseSetup:
    """Automate Supabase database setup"""
    
    def __init__(self, config_path: str = "config.json"):
        """
        Initialize
        
        Args:
            config_path: Configuration file path
        """
        with open(config_path) as f:
            config = json.load(f)
        
        self.supabase_url = config["supabase"]["url"]
        self.supabase_key = config["supabase"]["key"]
        self.supabase = create_client(self.supabase_url, self.supabase_key)
    
    def test_connection(self) -> bool:
        """
        Test Supabase connection
        
        Returns:
            True if connection successful
        """
        try:
            result = self.supabase.table("embeddings").select("*", count='exact').limit(1).execute()
            print(f"✅ Connection successful! (Found {result.count} documents)")
            return True
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def get_schema_sql(self) -> str:
        """
        Read schema.sql file
        
        Returns:
            SQL schema content
        """
        schema_path = Path(__file__).parent.parent / 'schema.sql'
        if not schema_path.exists():
            raise FileNotFoundError(f"schema.sql not found at {schema_path}")
        
        with open(schema_path, 'r', encoding='utf-8') as f:
            return f.read()
    
    def execute_sql(self, sql: str) -> bool:
        """
        Execute SQL via Supabase REST API
        
        Args:
            sql: SQL command
            
        Returns:
            True if successful
        """
        try:
            # Note: anon key cannot execute DDL statements
            # This requires service_role key or manual execution
            print("⚠️  DDL execution via anon key is not supported.")
            print("Please run schema.sql manually in Supabase SQL Editor:")
            print(f"   {self.supabase_url.replace('https://', 'https://supabase.com/dashboard/project/')}/sql/new")
            return False
        except Exception as e:
            print(f"❌ SQL execution failed: {e}")
            return False
    
    def check_table_exists(self, table_name: str) -> bool:
        """
        Check if table exists
        
        Args:
            table_name: Name of table
            
        Returns:
            True if table exists
        """
        try:
            self.supabase.table(table_name).select("*", count='exact').limit(1).execute()
            return True
        except:
            return False
    
    def check_function_exists(self, function_name: str) -> bool:
        """
        Check if function exists
        
        Args:
            function_name: Name of function
            
        Returns:
            True if function exists
        """
        try:
            self.supabase.rpc(function_name, {}).execute()
            return True
        except Exception as e:
            # If function doesn't exist, error message will contain "not found"
            if "not found" in str(e).lower() or "does not exist" in str(e).lower():
                return False
            # Function exists but parameters are wrong - that's OK
            return True
    
    def verify_setup(self) -> Dict[str, bool]:
        """
        Verify database setup
        
        Returns:
            Dictionary of checks and their status
        """
        checks = {}
        
        print("\n🔍 Verifying database setup...\n")
        
        # Check embeddings table
        checks['embeddings_table'] = self.check_table_exists('embeddings')
        status = "✅" if checks['embeddings_table'] else "❌"
        print(f"{status} embeddings table")
        
        # Check search function
        checks['search_function'] = self.check_function_exists('search_embeddings')
        status = "✅" if checks['search_function'] else "❌"
        print(f"{status} search_embeddings function")
        
        return checks
    
    def setup(self) -> bool:
        """
        Run complete setup
        
        Returns:
            True if setup successful
        """
        print("🚀 Knowledge Search - Database Setup\n")
        
        # Test connection
        print("1️⃣  Testing connection...")
        if not self.test_connection():
            return False
        
        print()
        
        # Verify setup
        print("2️⃣  Verifying setup...")
        checks = self.verify_setup()
        
        all_ok = all(checks.values())
        
        if all_ok:
            print("\n✅ Database is fully configured!")
            return True
        else:
            print("\n⚠️  Setup incomplete. Please run schema.sql manually:")
            print(f"\n   1. Open Supabase SQL Editor:")
            print(f"      {self.supabase_url.replace('https://', 'https://supabase.com/dashboard/project/')}/sql/new")
            print(f"\n   2. Copy and paste schema.sql content")
            print(f"\n   3. Click 'Run' to execute")
            print(f"\n   4. Run 'ks setup-db' again to verify")
            
            # Show schema.sql content
            try:
                schema_sql = self.get_schema_sql()
                print(f"\n📄 schema.sql preview:")
                print("=" * 60)
                print(schema_sql[:500] + "...")
                print("=" * 60)
            except:
                pass
            
            return False


if __name__ == '__main__':
    setup = DatabaseSetup()
    success = setup.setup()
    exit(0 if success else 1)
