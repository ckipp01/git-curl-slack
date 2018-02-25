#!/bin/sh

# Require a .conf file with your url for live and testing
.<path-to-conf-file>

# Check to see what parameter was passed in. Either the path you want it executed in or test if you are executing it by hand testing.
# If no path, it will default to the current directory
if [ "$1" = "test" ]
then
    curlUrl=$testUrl
else
    cd ${1:-.}
    curlUrl=$liveUrl
fi

# Set the original curlData here for the scope and the total count for affected directories
curlData=""
totalCount=0
hostname=`hostname`

  # Loop all directories
  for f in */
  do

     # Check if directory is a git repository
     if [ -d "$f/.git" ]
     then
         name="${f}"
         mod=0
         cd $f

         # Check for modified files
         modifiedNumber=$(git status | grep modified -c)
         if [ $modifiedNumber -gt 0 ]
         then
             mod=1
             if [ $modifiedNumber -gt 1 ]
             then
                 modifiedText="Modified Files"
             else
                 modifiedText="Modified File"
             fi
         fi

         # Check for deleted file
         deletedNumber=$(git status | grep deleted -c)
         if [ $deletedNumber -gt 0 ]
         then
             mod=1
             if [ $deletedNumber -gt 1 ]
             then
                deletedText="Deleted Files"
             else
                deletedText="Deleted File"
             fi
         fi

         # Check for untracked files
         untrackedStatus=$(git status | grep Untracked -c)
         if [ $untrackedStatus -gt 0 ]
         then
             mod=1
             untrackedText="Untracked Files"
         fi

         # Check to see if your branch is ahead of origin
         aheadStatus=$(git status | grep ahead -c)
         if [ $aheadStatus -gt 0 ]
         then
             mod=1
             aheadText="Branch is ahead of origin"
         fi

         # Check to see if any branches have diverged
         if [ $diverged -gt 0 ]
         then
             mod=1
             divergedText="Branch has diverged"
         fi

         # Check to see if there are any rulebreakers
         if [ ! $mod -eq 0 ]
         then
            totalCount=$(($totalCount + 1))
            count=0
            branch=$(git branch | sed -n '/\* /s///p')
            curlData="$curlData{\"title\":\"$name\nCurrent Branch: $branch\","
            if [ $aheadStatus -gt 0 ]
            then
                count=$(($count + 1))
                curlData="$curlData\"text\":\"$aheadText\n"
            fi
            if [ $modifiedNumber -gt 0 ]
            then
                if [ $count -gt 0 ]
                then
                    curlData="$curlData $modifiedNumber $modifiedText\n"
                else
                    curlData="$curlData\"text\":\"$modifiedNumber $modifiedText\n"
                fi
                count=$(($count + 1))
            fi
            if [ $untrackedStatus -gt 0 ]
            then
                if [ $count -gt 0 ]
                then
                    curlData="$curlData $untrackedText\n"
                else
                    curlData="$curlData\"text\":\"$untrackedText\n"
                fi
                count=$(($count + 1))
            fi
            if [ $deletedNumber -gt 0 ]
            then
                if [ $count -gt 0 ]
                then
                    curlData="$curlData $deletedNumber $deletedText\n"
                else
                    curlData="$curlData\"text\":\"$deletedNumber $deletedText\n"
                fi
            fi
            if [ $diverged -gt 0 ]
            then
                if [ $count -gt 0 ]
                then
                    curlData="$curlData $divergedText"
                else
                    curlData="$curlData\"text\":\"$divergedText"
                fi
            fi
            curlData="$curlData \" , \"color\":\"#B33A3A\"},"
         fi

     cd ../

     fi
 done

# Prepare the curl call and check to see if there are any offenders
case $totalCount in
    0)
        message="Good job message here"
        break;
        ;;
    1|2|3)
        message="${hostname}\n Almost good job message here"
        break;
        ;;
    4|5|6)
        message="${hostname}\n Time to pay attention message here"
        break;
        ;;
    *)
        message="${hostname}\n Get your life together message here"
        break;
        ;;
esac

if [ $totalCount -gt 0 ]
then
    payload="{\"text\": \"${message}\n Number of repositories that need attention: ${totalCount}\", \"attachments\": [ $curlData ]}"
else
    payload="{\"text\":\"${message}\"}"
fi

# The magic
curl \
    -X POST \
    -H "Content-type: application/json" \
    --data "$payload" \
    $curlUrl

