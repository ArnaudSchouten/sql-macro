create or replace editionable function show_duplicates (
	p_tab  in dbms_tf.table_t,
	p_cols in dbms_tf.columns_t,
	p_mode in integer default 1
) return varchar2 sql_macro as
	l_column_list     varchar2(1000);
	l_tab_column_list long;
begin
	/* p_mode: 1; show duplicate records
	   p_mode: 2; show rowids of duplicate records
	   p_mode: 3; show the first record of the duplicate records
	*/
	select
		listagg(column_value,',')
	  into l_column_list
	  from table ( p_cols );

	for i in 1..p_tab.column.count() loop
		l_tab_column_list := l_tab_column_list
		                     || p_tab.column(i).description.name
		                     || ',';
	end loop;

	l_tab_column_list := rtrim(
	                          l_tab_column_list,
	                          ','
	                     );
	return replace(
	              'select '
	              ||
			             case
				             when p_mode = 2 then
					             'rid'
				             else l_tab_column_list
			             end
	              || '
            from
                ( select
                        t.*
                       ,rowid rid
                       ,row_number() over(partition by {l_column_list} order by rowid) rn
                       ,count(*) over(partition by {l_column_list}) dup_cnt
                    from p_tab t
                ) t
            where '
	              || case
			             when p_mode = 1 then
				             ' dup_cnt > 1 '
			             when p_mode = 2 then
				             ' dup_cnt > 1 and rn > 1'
			             when p_mode = 3 then
				             ' dup_cnt > 1 and rn = 1'
		             end,
	              '{l_column_list}',
	              l_column_list
	       );

end show_duplicates;
/