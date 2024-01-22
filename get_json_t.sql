create or replace type string_type as
  object (
    v varchar2(4000)
  );
/

create or replace function get_json_t (
  p_tab in dbms_tf.table_t
, p_exclude_cols in dbms_tf.columns_t default null
, p_hide_null_values in boolean default true
, p_json_column in string_type default null
, p_date_columns dbms_tf.columns_t default null
) return clob sql_macro ( table ) is
  l_column_name    varchar2(32767);
  type key_value_rectype is record (
    k varchar2(1000)
  , v varchar2(1000)
  );
  type key_value_tabtype is
    table of key_value_rectype index by pls_integer;
  l_key_value_list key_value_tabtype;
  l_stmt           clob;
  j                pls_integer := 1;
begin
  for i in 1..p_tab.column.count loop
    if ( p_exclude_cols is null
    or not p_tab.column(i).description.name member of p_exclude_cols ) then
      l_column_name := trim(both '"' from p_tab.column(i).description.name);
      l_key_value_list(j).k := substr(lower(l_column_name), 1, 1)
                               || substr(replace(initcap(l_column_name), '_'), 2);
      if ( p_date_columns is not null
      and p_tab.column(i).description.name member of p_date_columns ) then
        l_key_value_list(j).v := 'to_char('
                                 || p_tab.column(i).description.name
                                 || ', ''yyyy-mm-dd''),';
      else
        l_key_value_list(j).v := p_tab.column(i).description.name
                                               || ',';
      end if;

      if ( i = p_tab.column.count ) then
        l_key_value_list(j).v := rtrim(l_key_value_list(j).v, ',');
      end if;

      j := j + 1;
    end if;
  end loop;

  l_stmt := 'select t.*, json_object(';
  for i in 1..l_key_value_list.count loop
    l_stmt := l_stmt
              || ''''
              || l_key_value_list(i).k
              || ''':'
              || l_key_value_list(i).v;
  end loop;

  if ( p_json_column is null ) then
    if ( p_hide_null_values ) then
      l_stmt := l_stmt
                || ' absent on null) document from p_tab t';
    else
      l_stmt := l_stmt
                || ') document from p_tab t';
    end if;
  else
    if ( p_hide_null_values ) then
      l_stmt := l_stmt
                || ' absent on null returning clob) '
                || p_json_column.v
                || ' from p_tab t';
    else
      l_stmt := l_stmt
                || ' returning clob) '
                || p_json_column.v
                || ' from p_tab t';
    end if;
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
  ) t
