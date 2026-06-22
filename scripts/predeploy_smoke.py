#!/usr/bin/env python3
"""
Pre-deploy smoke test for TAUG.
Verifies database contracts and runtime behavior.
"""

import os
import sys
import json
from datetime import datetime

# Add workers to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'workers'))

from taug_worker.config import WorkerConfig
from taug_worker.http_client import HttpClient
from taug_worker.supabase_rest import SupabaseRestClient


def test_env_config():
    """Verify environment variables are present."""
    print("\n=== 1. Environment Config ===")
    try:
        config = WorkerConfig.from_env()
        print(f"✅ SUPABASE_URL: {config.supabase_url[:30]}...")
        print(f"✅ SUPABASE_SERVICE_ROLE_KEY: present")
        return True
    except ValueError as e:
        print(f"❌ {e}")
        return False


def test_schema_reachable(client):
    """Verify DB schema is reachable."""
    print("\n=== 2. Schema Reachable ===")
    try:
        result = client._request('GET', 'companies', query={'select': 'id', 'limit': '1'})
        if isinstance(result, list):
            print(f"✅ Schema reachable, {len(result)} company found")
            return True
        else:
            print(f"❌ Unexpected response: {result}")
            return False
    except Exception as e:
        print(f"❌ Schema not reachable: {e}")
        return False


def test_portfolio_securities_relationship(client):
    """Verify portfolio_positions → securities relationship works."""
    print("\n=== 3. Portfolio → Securities Relationship (PGRST200 Test) ===")
    try:
        # This is the exact query that was failing
        result = client._request(
            'GET',
            'portfolio_positions',
            query={
                'select': '*,companies!inner(display_name),securities!left(ticker)',
                'limit': '1'
            }
        )
        if isinstance(result, list):
            print(f"✅ PGRST200 FIXED — query succeeded, {len(result)} rows")
            return True
        elif isinstance(result, dict) and 'code' in result:
            code = result.get('code', '')
            msg = result.get('message', '')
            if 'PGRST200' in str(code) or 'relationship' in str(msg).lower():
                print(f"❌ PGRST200 STILL EXISTS: {msg}")
                return False
            else:
                print(f"❌ Other error: {code} - {msg}")
                return False
        else:
            print(f"⚠️  Unexpected response type: {type(result)}")
            print(f"   Response: {str(result)[:200]}")
            return False
    except Exception as e:
        err_str = str(e)
        if 'PGRST200' in err_str or 'relationship' in err_str.lower():
            print(f"❌ PGRST200 STILL EXISTS: {e}")
            return False
        print(f"❌ Exception: {e}")
        return False


def test_portfolio_positions_query(client):
    """Verify portfolio positions query works."""
    print("\n=== 4. Portfolio Positions Query ===")
    try:
        result = client._request(
            'GET',
            'portfolio_positions',
            query={
                'select': '*,companies!inner(display_name),securities!left(ticker),investment_theses!left(stance,title)',
                'limit': '5'
            }
        )
        if isinstance(result, list):
            print(f"✅ Query succeeded, {len(result)} positions")
            if len(result) > 0:
                pos = result[0]
                company = pos.get('companies', {})
                print(f"   Sample: company={company.get('display_name', 'N/A')}")
            return True
        else:
            print(f"❌ Unexpected: {str(result)[:200]}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_pattern_intelligence_query(client):
    """Verify pattern intelligence query works."""
    print("\n=== 5. Pattern Intelligence Query ===")
    try:
        result = client._request(
            'GET',
            'portfolio_positions',
            query={
                'select': '*,companies!inner(display_name),investment_theses!left(stance)',
                'status': 'eq.closed',
                'limit': '5'
            }
        )
        if isinstance(result, list):
            print(f"✅ Pattern query succeeded, {len(result)} closed positions")
            return True
        else:
            print(f"❌ Unexpected: {str(result)[:200]}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_research_questions(client):
    """Verify research_questions table exists and is queryable."""
    print("\n=== 6. Research Questions Table ===")
    try:
        result = client._request(
            'GET',
            'research_questions',
            query={'select': 'id', 'limit': '1'}
        )
        if isinstance(result, list):
            print(f"✅ Table exists, {len(result)} rows")
            return True
        elif isinstance(result, dict) and 'code' in result:
            code = result.get('code', '')
            if 'PGRST205' in str(code):
                print(f"❌ Table not found: {result.get('message', '')}")
                return False
            else:
                print(f"⚠️  Other error: {result}")
                return False
        else:
            print(f"⚠️  Unexpected: {str(result)[:200]}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_learning_loop_query(client):
    """Verify learning loop query (closed positions with lessons)."""
    print("\n=== 7. Learning Loop Query ===")
    try:
        result = client._request(
            'GET',
            'portfolio_positions',
            query={
                'select': 'id,lessons_learned,outcome,exit_date',
                'status': 'eq.closed',
                'lessons_learned': 'not.is.null',
                'limit': '5'
            }
        )
        if isinstance(result, list):
            print(f"✅ Learning loop query succeeded, {len(result)} positions with lessons")
            return True
        else:
            print(f"❌ Unexpected: {str(result)[:200]}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def main():
    print("=" * 60)
    print("TAUG Pre-Deploy Smoke Test")
    print(f"Time: {datetime.now().isoformat()}")
    print("=" * 60)

    results = {}

    # 1. Environment
    results['env'] = test_env_config()
    if not results['env']:
        print("\n❌ ABORT: Missing environment variables")
        return False

    # Setup client
    config = WorkerConfig.from_env()
    http_client = HttpClient()
    client = SupabaseRestClient(
        http_client=http_client,
        supabase_url=config.supabase_url,
        service_role_key=config.supabase_service_role_key,
    )

    # 2. Schema reachable
    results['schema'] = test_schema_reachable(client)

    # 3. PGRST200 test (PRIMARY)
    results['pgrst200'] = test_portfolio_securities_relationship(client)

    # 4. Portfolio positions query
    results['positions'] = test_portfolio_positions_query(client)

    # 5. Pattern intelligence
    results['patterns'] = test_pattern_intelligence_query(client)

    # 6. Research questions
    results['questions'] = test_research_questions(client)

    # 7. Learning loop
    results['learning'] = test_learning_loop_query(client)

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    all_pass = True
    for key, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {key}: {status}")
        if not passed:
            all_pass = False

    print(f"\nPGRST200_FIXED={'true' if results['pgrst200'] else 'false'}")
    print(f"ALL_TESTS={'true' if all_pass else 'false'}")

    return all_pass


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
