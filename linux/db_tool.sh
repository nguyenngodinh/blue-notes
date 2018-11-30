#!/bin/bash
# bash db access


######----FUNCTION-DEFINITION------
# Gen 32 character alphanumeric string UPPER + lower
#Usage UUid_32 result_var
function UUid_32()
{
    local ___resultvar=$1
    
	NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	
	if [[ "$___resultvar" ]]; then
		eval $___resultvar="'$NEW_UUID'"
	else
		echo "$NEW_UUID"
	fi
	
}

# Gen 32 character alphanumeric string lower only
#Usage uuid_32 result_var
function uuid_32()
{
    local ___resultvar=$1
    
	new_uuid=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
	
	if [[ "$___resultvar" ]]; then
		eval $___resultvar="'$new_uuid'"
	else
		echo "$new_uuid"
	fi
}

#Usage: gen_number power result_var
function gen_number(){
	echo "param = $#"

	local ___resultvar=$2
	

	if [ $# -ne 2 ]; then
		gen_number_result=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 1)
	        #echo "number=$number"
	else
		power=$1
		# Gen random number 0-pow(10,power)-1
		temp=$((10**power-1))
		echo "Generate number range from 0 to $temp"
		gen_number_result=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^0*//' | head --bytes $power)
		if [ "$gen_number_result" == "" ]; then
		        gen_number_result=0
                echo "numberr=$gen_number_result"
		fi
	fi
	
	if [[ "$___resultvar" ]]; then
		eval $___resultvar="'$gen_number_result'"
	else
		echo "$gen_number_result"
	fi
}


#Usage: get_time result_var
function get_time(){
    local ___resultvar=$1
    POSIX_TIME_FORMAT="+\"%Y-%M-%d %H-%M-%S\""
    echo $POSIX_TIME_FORMAT
    current_time=$(date $POSIX_TIME_FORMAT)
    
    if [[ "$___resultvar" ]]; then
        eval $___resultvar="'$current_time'"
    else
        echo "$current_time"
    fi
}
#######---END-OF-FUNCTION-DEFINITION--------


#######----MAIN----
INSERT_QUERY_BGN="INSERT INTO "
TABLE="tewa.defended_area(id, last_update, status, violation_threshold, vertices, mission_complete_radius, description, priority, alias, type, name, longitude, latitude) "
VALUES_PRE="VALUES"
VALUES_CNT=(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
INSERT_QUERY_END=";"

entity_count=100
for ((i=0; i<$entity_count; i++)); do
    gen_number 10 id
    get_time last_update
    uuid_32 status
    uuid_32 violation_threshold
    uuid_32 vertices
    uuid_32 mission_complete_radius
    uuid_32 description
    uuid_32 priority
    uuid_32 alias
    uuid_32 type
    uuid_32 name
    uuid_32 longitude
    uuid_32 latitude
    VALUE_CNT="($id, $last_update, $status, $violation_threshold, $vertices, $mission_complete_radius, $description, $priority, $alias, $type, $name, $longitude, $latitude)"
    echo $VALUE_CNT
done


gen_number 100 number_result
uuid_32 uuid
UUid_32 UUid
echo "numbe gen: $number_result"
echo "uuid: $uuid     $(uuid_32)"
echo "UUid: $UUid     $(UUid_32)"


