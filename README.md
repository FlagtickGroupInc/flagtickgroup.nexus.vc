# Setting up Nexus Repository Manager to manage Laravel application packages involves deploying Nexus OSS (Open Source Software) repository and configuring it to serve as a local package registry.
## A.	Deploy Nexus Repository Manager

```yaml
nexus:
  image: sonatype/nexus3
  container_name: nexus
  ports:
    - "8081:8081"
  volumes:
    - nexus-data:/nexus-data
  environment:
    - INSTALL4J_ADD_VM_PARAMS=-Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:InitiatingHeapOccupancyPercent=75 -XX:G1ReservePercent=25 -XX:SoftRefLRUPolicyMSPerMB=50 -XX:+AlwaysPreTouch -Djava.util.prefs.userRoot=/nexus-data/javaprefs
  networks:
    - web_server
```
## B.	Deploy Nexus by running the updated docker-compose.yml file, then access it at http://localhost:8081.

```yaml
docker-compose up -d
```
Open the browser to view the interface.
![image](https://github.com/user-attachments/assets/dcfb0562-35c6-4200-be19-b100361eddbf)

## C.Configure Nexus for PHP Composer Packages
Log in using the username admin and the password retrieved by running the cat /nexus-data/admin.password command from the Nexus container environment. Below is a screenshot captured from the Nexus container for reference.
```yaml
docker exec -it nexus bash
cd
cat /nexus-data/admin.password
```
For example, log in using the username admin and the password Abc@123456.
![image](https://github.com/user-attachments/assets/d9470e50-83d6-4ee0-98e5-f718f5cd155c)

Create Raw Repository named composer-packages with the type set to Hosted and the Deployment Policy set to Allow Redeploy.
![image](https://github.com/user-attachments/assets/da94cf04-f42b-40fa-99d6-488438693e1b)

Modify the local.flagtickgroup.com.conf file to add an alias domain https://local-nexus.flagtickgroup.com and configure it to use upstream to proxy Nexus on port 8081.
```yaml
upstream nexus {
    server nexus:8081;
}

server {
    listen 443 ssl;
    server_name local-nexus.flagtickgroup.com;

    ssl_certificate /etc/ssl/flagtickgroup.com.crt;
    ssl_certificate_key /etc/ssl/flagtickgroup.com.key;

    location / {
        proxy_pass http://nexus;  
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Note:** Remember to add local-nexus.flagtickgroup.com to the /etc/hosts file.
![image](https://github.com/user-attachments/assets/2cff3af3-31dc-48e8-a55d-c93273e27238)

## D.	Configure Composer to Use the Nexus Repository
Update the composer.json file in your Laravel project to include the repository URL specified in the settings of the composer-packages repository.
```yaml
"repositories": {
    "nexus": {
        "type": "composer",
        "url": "https://nexus.flagtickgroup.com/repository/composer-packages/"
    }
}
```

**Note:** Let us configure Composer to pull packages from the specified Nexus repository using a command instead of adding it manually. 
```yaml
composer config repositories.nexus composer 
https://nexus.flagtickgroup.com/repository/composer-packages/
```

Here is a sample package description:
![image](https://github.com/user-attachments/assets/a815b9cb-03d4-457c-b9d0-9bd6271b3129)

Furthermore, we will have another file is packages.json, which links to the package declared above.
```yaml
{
  "packages": {
    "flagtickgroup/datahandling": {
      "1.0.0": {
        "name": "flagtickgroup/datahandling",
        "version": "1.0.0",
        "description": "FlagtickGroup Data Handling Package For Laravel.",
        "homepage": "https://www.flagtickgroup.com",
        "keywords": [
          "laravel",
          "php",
          "data"
        ],
        "license": "MIT",
        "authors": [
          {
            "name": "Flagtick Group",
            "email": "admin@flagtickgroup.com",
            "role": "Founder",
            "homepage": "https://www.flagtickgroup.com"
          }
        ],
        "require": {
          "php": "^8.0.2",
          "illuminate/support": "~5.0|~6.0|~7.0|^8.0|^9.0|^10.0"
        },
        "autoload": {
          "psr-4": {
            "FlagtickGroup\\DataHandling\\": "src/"
          }
        },
        "extra": {
          "laravel": {
            "providers": [
              "FlagtickGroup\\DataHandling\\Providers\\DataMappingServiceProvider"
            ]
          }
        },
        "minimum-stability": "stable",
        "prefer-stable": true,
        "dist": {
          "url": "https://nexus.flagtickgroup.com/repository/composer-packages/flagtickgroup-datahandling-1.0.0.zip",
          "type": "zip"
        }
      }
    }
  }
}
```

Below is Postman collection to test the Nexus on the remote server, ensuring it works correctly with the configurations provided. It also includes setup for packages 
such as flagtickgroup-datahandling-1.0.0.zip and packages.json.
```yaml
{
   "info": {
      "_postman_id": "ae92fbdc-b6ae-46a4-ad68-7d9ee36d5f4d",
      "name": "Nexus",
      "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
      "_exporter_id": "30348700"
   },
   "item": [
      {
         "name": "Get Packages List",
         "request": {
            "method": "GET",
            "header": [
               {
                  "key": "Authorization",
                  "value": "Basic {{base64Auth}}",
                  "type": "text"
               }
            ],
            "url": {
               "raw": "{{base_url}}/packages.json",
               "host": [
                  "{{base_url}}"
               ],
               "path": [
                  "packages.json"
               ]
            }
         },
         "response": []
      }
   ],
   "event": [
      {
         "listen": "prerequest",
         "script": {
            "type": "text/javascript",
            "packages": {},
            "exec": [
               ""
            ]
         }
      },
      {
         "listen": "test",
         "script": {
            "type": "text/javascript",
            "packages": {},
            "exec": [
               ""
            ]
         }
      }
   ],
   "variable": [
      {
         "key": "base_url",
         "value": "https://nexus.flagtickgroup.com/repository/composer-packages"
      },
      {
         "key": "base64Auth",
         "value": "BASE64_ENCODED_CREDENTIALS"
      }
   ]
}
```

**Note:** BASE64_ENCODED_CREDENTIALS is a Base64-encoded string in the format <username>:<password> used for logging into the Nexus repository on the remote server.
Using the command configures Composer to point to your Nexus repository (https://local-nexus.flagtickgroup.com/repository/composer-packages/) as a custom package source within a containerized environment.
Bonus: We need to determine whether the Nexus Repository Manager supports Composer repositories. If it does, the Composer format plugin must be installed and enabled to use Nexus for managing packages in PHP projects.
![image](https://github.com/user-attachments/assets/8ff86653-95e5-45fe-91f8-6e05e43f40ae)

Let install nexus-repository-composer plugin version 0.1+ requires Nexus Repository Manager 3.71.0 or newer.
```yaml
- ./resources/plugins:/nexus-data/deploy
```

Once the plugin installation and container restart, Nexus automatically detects and loads the .kar file from the /nexus-data/deploy directory, allowing you to verify the installation.
![image](https://github.com/user-attachments/assets/630b9279-88ae-45d7-9702-f2f192e7fff5)
**Note:** Normally, you don’t need to install the Composer plugin for Nexus; instead, you can use the raw self-hosted options as an alternative.

## E.	Publish Packages to the Raw Repository
Manually upload .zip package files to the raw repository in Nexus through the Nexus UI, as shown below. Composer cannot directly publish to raw repositories.
![image](https://github.com/user-attachments/assets/3502982f-79d8-4e38-9d4c-c7fea7d86057)
and set the Component attributes (e.g., vendor) to match your package structure. Then, use command like: composer require flagtickgroup/datahandling:1.0.0 to include the package in your Laravel project. 

## F.	Clone Package for Self-Hosting in Laravel Application
For example, go to GitHub or the vendor directory of the legacy Laravel application where the package (e.g., jamesdordoy/laravelvuedatatable) is currently used. 
Copy the package and place it into the vendor directory of the new Laravel project where it will be used. After that, update the namespace to use flagtickgroup as the private author prefix.
![image](https://github.com/user-attachments/assets/a58de307-a89f-48a4-af36-7ad8ce3b9f9b)

Let us check the composer.json file to see the namespace defined in the autoload section under PSR-4.
```yaml
"autoload": {
    "psr-4": {
        "JamesDordoy\\LaravelVueDatatable\\": "src/"
    },
    "classmap": [
        "src/"
    ]
},
```
Update composer.json in the Laravel project to Include this Package.
```yaml
"autoload": {
    "psr-4": {
        "App\\": "app/",
        "JamesDordoy\\LaravelVueDatatable\\": "vendor/laravelvuedatatable/src/"
    }
},
```
Now, customize it individually to follow the standard package of the Flagtick Group organization.
![image](https://github.com/user-attachments/assets/6a5db322-5181-4a62-8184-f31eb0c2b924)
After configuring PSR-4 autoloading in the root composer.json of a Laravel application, running these commands serves the following purposes:

```yaml
composer dump-autoload
php artisan vendor:publish --provider="FlagtickGroup\DataHandling\DataHandlingServiceProvider"
```
Finally, wrap it up and send it to nexus.flagtickgroup.com to store your package for use in multiple projects.
![image](https://github.com/user-attachments/assets/75dfbeab-1b30-4fb8-a440-ef0883d05eb2)
Refer to resources/nexus/packages.json and update it to include the newly uploaded flagtickgroup/flagtickgroup-datahandling-1.0.0.zip.
**Note:** Refer to the file resources/nexus/package/README.md.

## G. Nexus Repository for Self-Hosted NPM Packages
Assume we have node_module that is publicly shared on GitHub, but we want to customize it and store it in a private Nexus repository. We can follow the steps below:
![image](https://github.com/user-attachments/assets/10f92bcb-7301-4d22-9fc3-78195bfc1fe9)

Log in to Nexus, navigate to Repositories > Create Repository, and create a new repository named npm-packages, configured as an NPM (hosted) repository for NPM packages.
![image](https://github.com/user-attachments/assets/68536c9d-7993-4df0-90bc-d7c8a34d79e4)

Update the package.json to include Nexus-specific configuration:
```yaml
"publishConfig": {
   "registry": "https://nexus.flagtickgroup.com/repository/npm-packages/"
},
```

Log in to your Nexus repository for NPM authentication and configure Nexus as your NPM registry by running the following command:
```yaml
npm adduser --registry=https://nexus.flagtickgroup.com/repository/npm-packages/
```

Let us provide the following information:
    o	Username: Your Nexus username
    o	Password: Your Nexus password
    o	Email: Your email address

![image](https://github.com/user-attachments/assets/165b71c6-6b0b-4a14-97dd-a0a3e7055440)

If you don’t use the method above, update your .npmrc file (either global or project-specific) with the appropriate credentials for Nexus authentication.

```yaml
registry=https://nexus.flagtickgroup.com/repository/npm-packages/
//nexus.flagtickgroup.com/repository/npm-packages/:username=admin
//nexus.flagtickgroup.com/repository/npm-packages/:password=cJdbDSxdmocgdVH
```

And then verify your authentication with a specific npm registry.
```yaml
npm whoami --registry=https://nexus.flagtickgroup.com/repository/npm-packages/
```

Publish your package to a specific npm registry, in this case, a Nexus repository hosted at https://nexus.flagtickgroup.com/repository/npm-packages/
```yaml
"scripts": {
    "build": "gulp",
    "deploy": "gh-pages -d demo",
    "publish": "npm publish --registry=https://nexus.flagtickgroup.com/repository/npm-packages/"
},
```

**Note:** Run npm run publish to push your custom Node.js module package to the Nexus remote repository.
Leverage nvm list and nvm use to switch between Node.js versions on the local machine, which can help ensure you're using the latest npm/Node.js version to run npm run publish.
```yaml
nvm list

  * 18.0.0 (Currently using 64-bit executable)
    14.18.0
```

Check if the package is successfully published, you can use the npm view command:
```yaml
npm view bulma-radio --registry=https://nexus.flagtickgroup.com/repository/npm-packages/
```

Once you are trying to publish the same version (1.2.0), it will not update the package because NPM doesn't allow publishing the same version number. Make sure to update the version in your package.json (e.g., 1.2.1, 1.3.0, etc.) before running npm run publish.
![image](https://github.com/user-attachments/assets/33bb657c-3ebe-469e-b36d-c138927f38d5)

**Note:** Use Node version 14 to build and push the package. You can use Node version 18 for the project itself. 
    o  Packages: Use nvm list to check Node.js versions, then run nvm use 14 to switch to version 14 for npm run build and npm run publish.	
    ```yaml
      nvm use 14  
      npm run build
      npm run publish
    ```
    o  Projects: Switch to Node.js version 18 and pull the latest versions of node_modules packages.
    ```yaml
      nvm use 18
      npm install bulma-radio --registry=https://nexus.flagtickgroup.com/repository/npm-packages/
      npm run build
    ```






