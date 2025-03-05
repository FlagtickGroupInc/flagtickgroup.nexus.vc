## The process you've described is correct for adding a submodule to a Git repository.
```shell
https://github.com/FlagtickGroupInc/flagtickgroup.suite.vc/settings
```
## Use `git rm --cached <file/folder>` to remove the file or folder from the staging area and apply 
## the skip in the .gitignore file.

### Add a submodule to a Git repository
```shell
git submodule add git@github.com:FlagtickGroupInc/vc.flagtickgroup.git vc.flagtickgroup
```
| If you encounter an issue, remove the vc.flagtickgroup entry from .git/modules/vc.flagtickgroup.  
```shell
rm -rf .git/modules/vc.flagtickgroup
```

### After adding the submodule, you need to initialize it, which sets up the submodule’s configuration and fetches its content.
```shell
git submodule init
```

### After initializing the submodule, you need to fetch its contents and set it up in your project directory. This will clone the submodule repository into the specified directory (vc.flagtickgroup in this case).
```shell
git submodule update
```
| You can run both initialization and updating in one step with:
```shell
git submodule update --init --recursive 
```

#### Submodule addition will modify the .gitmodules file, so you need to commit those changes to your repository.
```shell
git add .gitmodules vc.flagtickgroup
git commit -m "Added vc.flagtickgroup submodule"
```

## Steps to Push Changes in the Submodule and Update Parent Repository

### Commit Changes in the Submodule (vc.flagtickgroup): First, commit your changes in the submodule (vc.flagtickgroup).
```shell
cd vc.flagtickgroup
git add .
git commit -m "Your commit message for vc.flagtickgroup"
git push origin master 
```

### Update the Submodule Reference in the Parent Repository
```shell
cd ../  
git status
git add vc.flagtickgroup
git commit -m "Update submodule vc.flagtickgroup to latest commit"
```

### Push the Parent Repository Changes:
```shell
git push origin master
```
