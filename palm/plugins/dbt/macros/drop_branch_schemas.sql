/*{# Cleans out all models generated for the current development schema 

    Only runs against the TEST database, will only work correctly when used in
    conjunction with the generate_schema_name macro

#}*/

{%- macro drop_branch_schemas(custom_test_db_name) -%}
    {%- set env = env_var("TEST_DB", var("TEST_DB", "TEST")) -%}

    {%- if target.database != env -%}
          {{ exceptions.raise_compiler_error("Branch cleanup can only execute in specified database; currently pointed at " ~ target.database) }}
    {%- endif -%}

    {%- set branch_query -%}
        SHOW TERSE SCHEMAS IN DATABASE {{env}};
        SELECT 'DROP SCHEMA {{env}}.' || "name" as drop_query FROM TABLE(RESULT_SCAN (LAST_QUERY_ID())) WHERE "name" LIKE UPPER('{{generate_schema_name()}}%')
    {%- endset -%}

    {% do log('getting schemas to drop with query ' ~ branch_query, info=True) %}
    {%- set drop_commands = run_query(branch_query).columns[0].values() -%}
    {% if drop_commands %}
        {% for drop_command in drop_commands %}
            {% do log('executing query ' ~ drop_command, True) %}
            {% do run_query(drop_command) %}
        {% endfor %}
    {% else %}
        {% do log('No schemas matching '~ generate_schema_name() ~' to clean.', True) %}
    {% endif %}

{%- endmacro -%}