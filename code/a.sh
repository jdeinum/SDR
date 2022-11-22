for FILE in ./*
do
 cat $FILE | mawk -f ~/Work/sdr/code/clean.awk > /tmp/cleaned.txt
 mv /tmp/cleaned.txt $FILE
 echo $FILE 
done
