# Covoiturage périurbain côté serveur
## Développé avec NodeJS LTS v18.17.1 et MariaDB v11.1.2 :
```bash
sudo systemctl start mariadb; mariadb --verbose -u user -p < "init.sql"; npm ci; npm start
```
## La configuration du serveur et de la connexion à la BDD se fait dans ./config.json
## Le serveur supporte les requêtes :
- PUT /account → créer compte
- POST /account → obtenir un token de connexion à mettre dans le header Authorization tel quel
- GET /account → obtenir les infos du compte
