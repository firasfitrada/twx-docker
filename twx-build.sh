#!/bin/bash
# twx-build.sh
# https://github.com/firasfitrada

extract(){
    echo -e "\033[32;1m Extracting the ThingWorx Dockerfile."
    dockerfiles_file_name="ThingWorx-Platform-DockerFiles"
    check_dockerfiles=$(find staging/ -type f -name "*$dockerfiles_file_name*.tar.gz")
    if [ -n "$check_dockerfiles" ]; then
        echo -e "\033[32;5m[✔]\033[0m The following Dockerfiles have been found: \033[33;1m$check_dockerfiles\033[0m"
        tar -xzf $check_dockerfiles
        echo -e "\033[32;5m[✔]\033[0m Dockerfiles have already been extracted."
    else
        echo -e "\033[31;5m[✘]\033[0m No Dockerfiles were found."
        exit
    fi
}

extract_security(){
    echo -e "\033[32;1m Extracting the ThingWorx Security Management Tool."
    dockerfiles_file_name="Security-Management-Tool-DockerFiles"
    check_dockerfiles=$(find staging/ -type f -name "*$dockerfiles_file_name*.tar.gz")
    if [ -n "$check_dockerfiles" ]; then
        echo -e "\033[32;5m[✔]\033[0m The following Dockerfiles have been found: \033[33;1m$check_dockerfiles\033[0m"
        sudo tar -xzf $check_dockerfiles
        echo -e "\033[32;5m[✔]\033[0m Dockerfiles have already been extracted."
    else
        echo -e "\033[31;5m[✘]\033[0m No Dockerfiles were found."
        exit
    fi
}

cleanup(){
    echo -e "\033[31;1m Cleaning Up the ThingWorx Dockerfile."
    echo -ne "\033[33;1m[?]\033[0m Would you like to clean up the ThingWorx Dockerfiles? (Y/N): ";
    read confirm_cleanup_dockerfiles
    if [ "$confirm_cleanup_dockerfiles" == "y" ] || [ "$confirm_cleanup_dockerfiles" == "Y" ]; then
        sudo rm -rf docker-compose* conf build build.env build.sh *.yml dockerfiles *.txt example staging/xmlmerge* staging/template* staging/platform-settings* staging/security-common*
        echo -e "\033[32;1m[✔]\033[0m The Dockerfiles have been successfully cleaned";
        echo -ne "\033[33;1m[?]\033[0m Would you like to delete all files within the staging folder? (Y/N): ";
        read confirm_delete_staging
        if [ "$confirm_delete_staging" == "y" ] || [ "$confirm_delete_staging" == "Y" ]; then
            sudo rm staging/*.tar.gz staging/*.zip
            echo -e "\033[32;1m[✔]\033[0m The staging folder has been successfully deleted.";
            echo -e "\033[32;1m[✔]\033[0m The Dockerfiles have been successfully cleaned up.";
        else
            echo -e "\033[31;1m[✘]\033[0m The staging folder has not been deleted."
            echo -e "\033[32;1m[✔]\033[0m The Dockerfiles have been successfully cleaned up.";
        fi
    else
        echo -e "\033[31;1m[✘]\033[0m Aborted."
        exit
    fi
}

setup_twx_postgres(){
    echo -e "\033[32;1m Setup ThingWorx PostgreSQL Platform Docker Images."
    file_env="build.env"
    postgres_platform_file_name="ThingWorx-Platform-Postgres"
    jdk11_file_name="amazon-corretto"
    apache_tomcat_file_name="apache-tomcat-"
    template_processor_file_name="template-processor"
    xmlmerge_file_name="xmlmerge"

    check_postgres_platform=$(find staging/ -type f -name "*$postgres_platform_file_name*.zip")
    check_jdk11=$(find staging/ -type f -name "$jdk11_file_name*linux-x64.tar.gz")
    check_apache_tomcat=$(find staging/ -type f -name "$apache_tomcat_file_name*.tar.gz")
    check_template_processor=$(find staging/ -type f -name "$template_processor_file_name*application.tar.gz")
    check_xmlmerge=$(find staging/ -type f -name "$xmlmerge_file_name*application.tar.gz")

    if [ -n "$check_postgres_platform" ]; then echo -e "\033[32;1m[✔]\033[0m The ThingWorx Platform PostgreSQL file has been found: \033[33;1m$check_postgres_platform\033[0m"; else echo -e "\033[31;1m[✘]\033[0m TThe ThingWorx Platform PostgreSQL file has not been found."; exit; fi
    if [ -n "$check_jdk11" ]; then echo -e "\033[32;1m[✔]\033[0m The JDK 11 file has been found: \033[33;1m$check_jdk11\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The JDK 11 file has not been found."; exit; fi
    if [ -n "$check_apache_tomcat" ]; then echo -e "\033[32;1m[✔]\033[0m The Apache Tomcat 9 file has been found: \033[33;1m$check_apache_tomcat\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The Apache Tomcat 9 file has not been found."; exit; fi
    if [ -n "$check_template_processor" ]; then echo -e "\033[32;1m[✔]\033[0m The template processor file has been found: \033[33;1m$check_template_processor\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The template processor file has not been found."; exit; fi
    if [ -n "$check_xmlmerge" ]; then echo -e "\033[32;5m[✔]\033[0m The XMLmerge file has been found: \033[33;1m$check_xmlmerge\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The XMLmerge file has not been found."; exit; fi

    cleaned_postgres_platform_name=$(echo "$check_postgres_platform" | sed 's/staging\///')
    cleaned_jdk11_name=$(echo "$check_jdk11" | sed 's/staging\///')
    cleaned_apache_tomcat_name=$(echo "$check_apache_tomcat" | sed 's/staging\///')
    cleaned_template_processor_name=$(echo "$check_template_processor" | sed 's/staging\///')
    cleaned_xmlmerge_name=$(echo "$check_xmlmerge" | sed 's/staging\///')
    cleaned_apache_version_name=$(echo "$check_apache_tomcat" | sed 's/.*-\([0-9]*\.[0-9]*\.[0-9]*\)\..*/\1/')

    echo -e "\033[32;1m[✔]\033[0m Updating build.env file."
    sudo sed -i "s/^\(PLATFORM_POSTGRES_ARCHIVE=\).*/\1$cleaned_postgres_platform_name/" "$file_env"
    sudo sed -i "s/^\(JAVA_ARCHIVE=\).*/\1$cleaned_jdk11_name/" "$file_env"
    sudo sed -i "s/^\(TOMCAT_VERSION=\).*/\1$cleaned_apache_version_name/" "$file_env"
    sudo sed -i "s/^\(TOMCAT_ARCHIVE=\).*/\1$cleaned_apache_tomcat_name/" "$file_env"
    sudo sed -i "s/^\(TEMPLATE_PROCESSOR_ARCHIVE=\).*/\1$cleaned_template_processor_name/" "$file_env"
    sudo sed -i "s/^\(XMLMERGE_ARCHIVE=\).*/\1$cleaned_xmlmerge_name/" "$file_env"

    echo -e "\033[32;1m[✔]\033[0m Updating platform-settings-overrides.json.j2 file."
    line_old_password_platform='"password": "encrypt.db.password",'
    line_new_password_platform='"password": "{% if env_var("ENCRYPT_CREDENTIALS", "false") == "true" %}encrypt.db.password{% else %}{{ env_var("TWX_DATABASE_PASSWORD", "") }}{% endif %}",'
    postgres_platfrom_settings_file=dockerfiles/platform/postgres/imageFiles/@var_dirs@/THINGWORX_PLATFORM_SETTINGS/platform-settings-overrides.json.j2
    sudo sed -i "s/$line_old_password_platform/$line_new_password_platform/" "$postgres_platfrom_settings_file"
}

build_twx_postgres(){
    echo -e "\033[32;5m[✔]\033[0m Initiating the build process for the ThingWorx PostgreSQL Docker images."
    file_env="build.env"
    check_base_image_name=$(grep "BASE_IMAGE=" "$file_env" | cut -d'=' -f2)
    sudo docker pull $check_base_image_name
    sudo ./build.sh postgres > /tmp/apt_update_output 2>&1 &
    
    loading_chars=("☐ ☐ ☐ ☐ ☐" "☑ ☐ ☐ ☐ ☐" "☑ ☑ ☐ ☐ ☐" "☑ ☑ ☑ ☐ ☐" "☑ ☑ ☑ ☑ ☐" "☑ ☑ ☑ ☑ ☑")
    
    while ps -p $! > /dev/null; do
        for char in "${loading_chars[@]}"; do
            sudo printf "\r[%s] Please wait a moment" "$char"
            sudo sleep 0.1
        done
    done
    
    sudo printf "\r"
}

setup_twx_mssql(){
    echo -e "\033[32;1m Setup ThingWorx MSSQL Platform Docker Images."
    file_env="build.env"
    mssql_platform_file_name="ThingWorx-Platform-Mssql"
    jdk11_file_name="amazon-corretto"
    apache_tomcat_file_name="apache-tomcat"
    template_processor_file_name="template-processor"
    xmlmerge_file_name="xmlmerge"
    sqljdbc_file_name="sqljdbc"

    check_mssql_platform=$(find staging/ -type f -name "*$mssql_platform_file_name*.zip")
    check_jdk11=$(find staging/ -type f -name "$jdk11_file_name*linux-x64.tar.gz")
    check_apache_tomcat=$(find staging/ -type f -name "$apache_tomcat_file_name*.tar.gz")
    check_template_processor=$(find staging/ -type f -name "$template_processor_file_name*application.tar.gz")
    check_xmlmerge=$(find staging/ -type f -name "$xmlmerge_file_name*application.tar.gz")
    check_sqljdbc=$(find staging/ -type f -name "$sqljdbc_file_name*.tar.gz")

    if [ -n "$check_mssql_platform" ]; then echo -e "\033[32;1m[✔]\033[0m The ThingWorx Platform MSSQL file has been found: \033[33;1m$check_mssql_platform\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The ThingWorx Platform MSSQL file has not been found."; exit; fi
    if [ -n "$check_jdk11" ]; then echo -e "\033[32;1m[✔]\033[0m The JDK 11 file has been found: \033[33;1m$check_jdk11\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The JDK 11 file has not been found."; exit; fi
    if [ -n "$check_apache_tomcat" ]; then echo -e "\033[32;1m[✔]\033[0m The Apache Tomcat 9 file has been found: \033[33;1m$check_apache_tomcat\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The Apache Tomcat 9 file has not been found."; exit; fi
    if [ -n "$check_template_processor" ]; then echo -e "\033[32;1m[✔]\033[0m The template processor file has been found: \033[33;1m$check_template_processor\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The template processor file has not been found."; exit; fi
    if [ -n "$check_xmlmerge" ]; then echo -e "\033[32;5m[✔]\033[0m The XMLmerge file has been found: \033[33;1m$check_xmlmerge\033[0m"; else echo -e "\033[31;1m[✘]\033[0m The XMLmerge file has not been found."; exit; fi
    if [ -n "$check_sqljdbc" ]; then echo -e "\033[32;1m[✔]\033[0m SQLJDBC driver file have been found: \033[33;1m$check_sqljdbc\033[0m"; else echo -e "\033[31;1m[✘]\033[0m SQLJDBC driver file not found."; exit; fi

    cleaned_mssql_platform_name=$(echo "$check_mssql_platform" | sed 's/staging\///')
    cleaned_jdk11_name=$(echo "$check_jdk11" | sed 's/staging\///')
    cleaned_apache_tomcat_name=$(echo "$check_apache_tomcat" | sed 's/staging\///')
    cleaned_template_processor_name=$(echo "$check_template_processor" | sed 's/staging\///')
    cleaned_xmlmerge_name=$(echo "$check_xmlmerge" | sed 's/staging\///')
    cleaned_sqljdbc_name=$(echo "$check_sqljdbc" | sed 's/staging\///')
    cleaned_apache_version_name=$(echo "$check_apache_tomcat" | sed 's/.*-\([0-9]*\.[0-9]*\.[0-9]*\)\..*/\1/')

    echo -e "\033[32;5m[✔]\033[0m Updating build.env file."
    sudo sed -i "s/^\(PLATFORM_MSSQL_ARCHIVE=\).*/\1$cleaned_mssql_platform_name/" "$file_env"
    sudo sed -i "s/^\(JAVA_ARCHIVE=\).*/\1$cleaned_jdk11_name/" "$file_env"
    sudo sed -i "s/^\(TOMCAT_ARCHIVE=\).*/\1$cleaned_apache_tomcat_name/" "$file_env"
    sudo sed -i "s/^\(TOMCAT_VERSION=\).*/\1$cleaned_apache_version_name/" "$file_env"
    sudo sed -i "s/^\(TEMPLATE_PROCESSOR_ARCHIVE=\).*/\1$cleaned_template_processor_name/" "$file_env"
    sudo sed -i "s/^\(XMLMERGE_ARCHIVE=\).*/\1$cleaned_xmlmerge_name/" "$file_env"
    sudo sed -i "s/^\(SQLDRIVER_ARCHIVE=\).*/\1$cleaned_sqljdbc_name/" "$file_env"

    echo -e "\033[32;5m[✔]\033[0m Updating platform-settings-overrides.json.j2 file."
    line_old_password_platform='"password": "encrypt.db.password"'
    line_new_password_platform='"password": "{% if env_var("ENCRYPT_CREDENTIALS", "false") == "true" %}encrypt.db.password{% else %}{{ env_var("TWX_DATABASE_PASSWORD", "") }}{% endif %}"'
    mssql_platfrom_settings_file=dockerfiles/platform/mssql/imageFiles/@var_dirs@/THINGWORX_PLATFORM_SETTINGS/platform-settings-overrides.json.j2
    sudo sed -i "s/$line_old_password_platform/$line_new_password_platform/" "$mssql_platfrom_settings_file"
}

build_twx_mssql(){
    echo -e "\033[32;5m[✔]\033[0m Initiating the build process for the ThingWorx MSSQL Docker images."
    file_env="build.env"
    check_base_image_name=$(grep "BASE_IMAGE=" "$file_env" | cut -d'=' -f2)
    sudo docker pull $check_base_image_name
    sudo ./build.sh mssql > /tmp/build_image 2>&1 &
    
    loading_chars=("☐ ☐ ☐ ☐ ☐" "☑ ☐ ☐ ☐ ☐" "☑ ☑ ☐ ☐ ☐" "☑ ☑ ☑ ☐ ☐" "☑ ☑ ☑ ☑ ☐" "☑ ☑ ☑ ☑ ☑")
    
    while ps -p $! > /dev/null; do
        for char in "${loading_chars[@]}"; do
            sudo printf "\r[%s] Please wait a moment" "$char"
            sudo sleep 0.1
        done
    done
    
    sudo printf "\r"
}


if [ "$1" == "extract" ]; then extract;
elif [ "$1" == "cleanup" ]; then cleanup;
elif [ "$1" == "setup-postgres" ]; then setup_twx_postgres;
elif [ "$1" == "build-postgres" ]; then build_twx_postgres;
elif [ "$1" == "setup-mssql" ]; then setup_twx_mssql;
elif [ "$1" == "build-mssql" ]; then build_twx_mssql;
else
    echo ""; echo -e "\033[31;5m[✘]\033[0m Invalid Command /twx-build.sh \033[31;1m$1\033[0m"; \
    echo ""; echo "[----- Command Options -----]"
    echo -e "\033[32;1m./twx-build.sh \033[35;1m extract \033[0m"
    echo -e "\033[32;1m./twx-build.sh \033[35;1m setup-postgres \033[0m"
    echo -e "\033[32;1m./twx-build.sh \033[35;1m build-postgres \033[0m"
    echo -e "\033[32;1m./twx-build.sh \033[35;1m setup-mssql \033[0m"
    echo -e "\033[32;1m./twx-build.sh \033[35;1m build-mssql \033[0m"
    echo -e "\033[32;1m./twx-build.sh \033[35;1m cleanup \033[0m"
fi