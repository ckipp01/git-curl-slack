#!/bin/sh

# Check to see if a parameter was passed in. It should either be test if you are running in a directory and it will shoot
# it to a test webook, or the path you'd like it to be executed in, which will then shoot it to the actually webhook url.
if [ "$1" = "test" ]
then
    curlUrl="Put hook url for testing here"
else
    cd $1
    curlUrl="Put main hook url here"
fi

# Set the original curlData here and the total count for affected directories
curlData=""
totalCount=0

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

         # Check to see if there are any rulebreakers
         if [ ! $mod -eq 0 ]
         then
            totalCount=$(($totalCount + 1))
            count=0
            curlData="$curlData{\"title\":\"$name\","

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
                    curlData="$curlData $deletedNumber $deletedText" 
                else
                    echo $count
                    curlData="$curlData\"text\":\"$deletedNumber $deletedText"
                fi
            fi
            curlData="$curlData \" , \"color\":\"#B33A3A\"},"
         fi

     cd ../

     fi
 done

#prepare the curl call and check to see if there are any offenders
if [ $totalCount -gt 0 ]
then
    payload="{\"text\":\"Input Message here\", \"attachments\": [ $curlData ]}"
else
    payload="{\"text\":\"Input Message here\"}"
fi

#The magic
curl \
    -X POST \
    -H "Content-type: application/json" \
    --data "$payload" \
    $curlUrl

