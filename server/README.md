# Covoiturage périurbain côté serveur
## Développé avec NodeJS LTS v18.17.1 et MariaDB v11.1.2 :
```bash
sudo systemctl start mariadb; mariadb --verbose -u user -p < "init.sql"; npm ci --only=production; npm start
```
## La configuration du serveur et de la connexion à la BDD se fait dans ./config.json
### J'utilise les credentials user:user sur la databse cvp [(documentation)](https://wiki.archlinux.org/title/MariaDB#Add_user)
## Le serveur supporte les requêtes :
- /account (GET est authentifié, le reste est ouvert)
    - PUT: créer compte
    - DELETE: TODO
    - PATCH: mettre à jour le role, town
    - POST: obtenir un token de connexion à mettre dans le header Authorization tel quel
    - GET: account → obtenir les infos du compte

![Diagramme de classe](./src/img/Diagramme_de_classe_cvp.png)