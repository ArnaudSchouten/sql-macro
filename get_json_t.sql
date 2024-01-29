create or replace type string_type as
  object (
    v varchar2(4000)
  );
/

create or replace function get_json_t (
  p_tab              in dbms_tf.table_t
 ,p_exclude_cols     in dbms_tf.columns_t default null
 ,p_hide_null_values in boolean default true
 ,p_json_column      in string_type default null
 ,p_date_columns     in dbms_tf.columns_t default null
 ,p_boolean_columns  in dbms_tf.columns_t default null
) return clob
  sql_macro ( table )
is

  l_column_name      varchar2(200);
  l_json_column_name varchar2(200);
  type key_value_rectype is record (
      k varchar2(200)
    ,v varchar2(200)
  );
  type key_value_tabtype is
    table of key_value_rectype index by pls_integer;
  l_key_value_list   key_value_tabtype;
  l_stmt             clob;
  j                  pls_integer := 1;
begin
  l_json_column_name := nvl(p_json_column.v,'document');
  for col in values of p_tab.column loop
    if ( p_exclude_cols is null or not col.description.name member of p_exclude_cols ) then
      l_column_name         := replace(col.description.name,'"','''');
      l_key_value_list(j).k := substr(lower(l_column_name),1,2) || substr(replace(initcap(l_column_name),'_'),3);

      l_key_value_list(j).v := case
        when (
          p_date_columns is not null
          and col.description.name member of p_date_columns
        ) then
          'to_char(' || col.description.name || ', ''yyyy-mm-dd'')'
        when (
          p_boolean_columns is not null
          and col.description.name member of p_boolean_columns
        ) then
          'decode(lower(' || col.description.name || '),''j'',''true'', ''ja'',''true'', ''y'', ''true'',''false'') format json'
        else col.description.name
      end || ',';

      j                     := j + 1;
    end if;
  end loop;

  if ( l_key_value_list.count() > 0 ) then
    l_key_value_list(l_key_value_list.last()).v := rtrim(l_key_value_list(l_key_value_list.last()).v,',');
  end if;

  l_stmt             := 'select t.*, json_object(';
  for val in values of l_key_value_list loop
    l_stmt := l_stmt || val.k || ':' || val.v;
  end loop;

  if ( p_hide_null_values ) then
    l_stmt := l_stmt || ' absent on null returning clob) ' || l_json_column_name || ' from p_tab t';
  else
    l_stmt := l_stmt || 'returning clob) ' || l_json_column_name || ' from p_tab t';
  end if;

  dbms_tf.trace(l_stmt);
  return l_stmt;
end get_json_t;

/*
 examples
*/
select
  t.owner
, t.noot
from
  get_json_t(p_tab => large_table
, p_exclude_cols => columns(object_name
, owner)
, p_hide_null_values => true
, p_json_column => new string_type('noot') ) t
where
  rownum < 20;

 /*
   passing with query
 */   
create or replace type string_list as
  table of varchar2(4000);
/

with data as (
  select
    d.deptno
  , d.dname
  , cast(multiset(
      select
        e.ename
      from
        emp e
      where
        e.deptno = d.deptno
    ) as string_list) employees
  from
    dept d
)
select
  t.*
from
  get_json_t(
    p_tab => data
  , p_json_column => string_type('aap')
  ) t;
