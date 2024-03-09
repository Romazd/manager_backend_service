# GITHUB API - BACKEND SERVICE

Esta aplicación `ManagerBackendService` solamente es un servicio API por lo que todas las acciones realizan conexiones con el API de GITHUB.


## Creación de App

En este ejemplo utilizamos el `RailsAppsController` para establecer un endpoint (acción create) dónde se puede enviar el nombre de la aplicación que se creará. Utilizamos `tmpdir` para poder crear de forma temporal los archivos que se generan al hacer una nueva aplicación o engine.

A continuación está la sección más importante de lo que podemos encontrar en el controlador `RailsAppsController` donde de forma directa utilizando el comando `system` podemos establecer las instrucciones que normalmente utilizaríamos en la terminal. En este snippet podemos encontrar los pasos del proceso de creación de la aplicación.
```
Dir.mktmpdir do |dir|
  Dir.chdir(dir) do
    # PASO 1: Creación de la aplicación
    system("rails new #{app_name}")

    Dir.chdir(app_name) do
      # PASO 2: Primer commit de la creación de la aplicación
      system('git init')
      system('git config user.email "segundo.marco@gmail.com"')
      system('git config user.name "Marco Sandoval"')
      system('git add .')
      system('git commit -m "Initial commit"')

      github_token = ENV['ACCESS_PAT']
      github_username = 'Romazd'
      repo_name = "#{app_name}"

      # PASO 3: Creación del repositorio en Github
      system("curl -X POST -H 'Authorization: token #{github_token}' -H 'Content-Type: application/json' https://api.github.com/user/repos -d '{\"name\":\"#{app_name}\"}'")
      # PASO 4: Commit de la aplicación al repositorio recién creado
      system("git remote add origin https://#{github_username}:#{github_token}@github.com/#{github_username}/#{repo_name}.git")
      system('git branch -M main') # Ensure the branch is named 'main'
      system('git push -u origin main') # Push using the correct branch name
    end
  end
end
```

## RepoManagerController
Dentro del controlador existen las acciones `list_user_repos`, `add_repo_collaborator`, `remove_repo_collaborator`, `create_webhook`, `protect_branch` y `create_workflow_webhook`. Cada una tiene una función diferente sin embargo comparten la misma estructura, el entender esta estructura permite crear nuevas acciones que cumplan nuevas funciones. Para entender esta estructura se puede observa la acción `add_repo_collaborator`:

```
  def add_repo_collaborator
    repo_name = params[:repo_name]
    username_to_add = params[:username_to_add]
    permission = params[:permission] || 'push'
    access_token = Rails.application.credentials.dig(:github_access, :pat)
    uri = URI("https://api.github.com/repos/Romazd/#{repo_name}/collaborators/#{username_to_add}")
    request = Net::HTTP::Put.new(uri)
    request["Authorization"] = "token #{access_token}"
    request.body = {permission: permission}.to_json
  
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
    if response.is_a?(Net::HTTPSuccess)
      add_response = JSON.parse(response.body)
      render json: { add_response: add_response }
    else
      render json: { error: 'Failed to add a collaborator' }, status: :bad_request
    end
  rescue => e
    puts "Error adding collaborator: #{e.message}"
    false
  end
```
La acción recibe como parámetros aquello que venga en el body del request. Todas las acciones dentro de este controlador reciben los parámetros de la misma manera, dependiende de los atributos necesarios para la acción son aquellos que se utilizarán.

Todas las acciones dentro de este controlador utilizan un `access_token` o `Personal Access Token` se generan dentro de Github en la sección `Settings` >> `Developer Settings` >> `Tokens (Classic)` con permiso tipo `repo` y son la forma de autenticar el request para poder realizar las acciones que se necesitan.

El `uri` es uno de los elementos más importante ya que define a dónde se hará hit. El mismo uri tiene indicaciones de con que elementos va a interactuar por ejemplo en el caso de `add_repo_collaborator` esta el siguiente url:
```
"https://api.github.com/repos/Romazd/#{repo_name}/collaborators/#{username_to_add}"
```
En este url se apunta a un repositorio en específico, se agrega la dirección de colaboradores y finalmente se agrega el nombre del usuario con el que se desea interactuar. Finalmente a la hora de inicializar el request como por ejemplo en este caso se utiliza `Net::HTTP::Put.new(uri)` para indicar que será una acción put, o en otras palabras que se desea agregar a ese usuario dentro del repositorio pero si se toma en cuenta la acción `remove_repo_collaborator` tiene el mismo uri pero el request es diferente `Net::HTTP::Delete.new(uri)` indicando en este caso que se desea eliminar al colaborador del repositorio.

El último elemento importante es el `body` que permite agregar información al request que puede ser de utilidad, por ejemplo en las acciones `create_webhook` y `protect_branch` permiten establecer las reglas con las que deberá contar tanto el webhook como el branch.

Finalmente es importante aclarar que no todos los request tienen una respuesta con un body, algunas respuestas solo tienen una confimación 200 y no hay otro parámetro para revisar que la acción se realizó correctamente más que revisar manualmente que se haya realizado alguna modificación.

