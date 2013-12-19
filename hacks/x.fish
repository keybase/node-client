set lines (echo 'select sig_id, payload_json FROM signatures' | kbdb -N  )
for line in $lines;
   set id (echo $line | awk ' { print $1 }' )
   set prev (echo $line | awk ' { print $2 } ' | jsonpipe | grep "^/prev" | awk ' { print $2 } ' )
   if begin; test "$prev" != ""; and test $prev != "null" ; end;
      echo "UPDATE signatures SET prev=$prev WHERE sig_id = '$id'" | kbdb
   end
end
