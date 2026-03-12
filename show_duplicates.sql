create or replace function show_duplicates
(
  p_tab  in dbms_tf.table_t
 ,p_cols in dbms_tf.columns_t
 ,p_mode in dbms_tf.columns_t default null
) return clob sql_macro as
  l_column_list     varchar2(1000);
  l_tab_column_list long;
  l_stmt            clob;
  l_mode  pls_integer;
begin
  /* voorbeeld:
  
    select *
    from show_duplicates(p_tab  => lak_import
                        ,p_cols => columns(loonheffing_nummer, ddstart_periode, ddeind_periode, sv_loon)
                        ,p_mode => columns("1")
                        ) t
  
     p_mode: 1; show duplicate records
     p_mode: 2; show rowids of duplicate records
     p_mode: 3; show the first record of the duplicate records
  */
  -- mode
  if (p_mode.exists(1)) then
    l_mode := to_number(trim(both '"' from p_mode(1)) default null on conversion error);
  end if;
  
  l_mode := nvl(l_mode, 1);

  -- get the columns to compare
  select listagg(column_value, ',')
    into l_column_list
    from table(p_cols);

  -- get all table columns
  for i in 1 .. p_tab.column.count()
  loop
    l_tab_column_list := l_tab_column_list || p_tab.column(i).description.name || ',';
  end loop;

  l_tab_column_list := rtrim(l_tab_column_list, ',');

  l_stmt := replace('select ' || case
                      when l_mode = 2 then
                       'rid'
                      else
                       l_tab_column_list
                    end || '
            from
                ( select
                        t.*
                       ,rowid rid
                       ,row_number() over(partition by {l_column_list} order by rowid) rn
                       ,count(*) over(partition by {l_column_list}) dup_cnt
                    from p_tab t
                ) t
            where ' || case
                      when l_mode = 1 then
                       ' dup_cnt > 1 '
                      when l_mode = 2 then
                       ' dup_cnt > 1 and rn > 1'
                      when l_mode = 3 then
                       ' dup_cnt > 1 and rn = 1'
                    end
                   ,'{l_column_list}'
                   ,l_column_list);

  return l_stmt;

end show_duplicates;
/
