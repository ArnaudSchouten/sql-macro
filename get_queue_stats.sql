create or replace function get_queue_stats
return clob 
sql_macro 
is
  l_stmt clob;
begin
  for q_rec in (select t.name queue_name
                      ,t.queue_table
                  from user_queues t
                 where t.queue_type = 'NORMAL_QUEUE')
  loop
    l_stmt := l_stmt || 'select '''|| q_rec.queue_name ||''' queue_name, case state when 3 then ''Fout'' else ''Oke'' end status, count(*) aantal from ' || q_rec.queue_table || ' group by q_name, state union all ';   
  end loop;

  l_stmt := rtrim(l_stmt, 'union all');
  dbms_tf.trace(l_stmt);

  return(l_stmt);
end get_queue_stats;
/
