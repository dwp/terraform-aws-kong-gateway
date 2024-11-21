#commit_message=$(cat commit_message.txt)

commit_message="ello moto"

echo ${commit_message}

if [[ "${commit_message,,}" == *"major release"* ]]; then
  echo ::set-output name=semver_increment::"m"
elif [[ "${commit_message,,}" == *"minor release"* ]]; then
  echo ::set-output name=semver_increment::"i"
else
  echo ::set-output name=semver_increment::"p"
fi
