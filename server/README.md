# Covoiturage périurbain côté serveur
## Développé avec NodeJS LTS v18.17.1 et MariaDB v11.1.2 :
```bash
sudo systemctl start mariadb; npm ci; npm start
```
## La configuration du serveur se fait dans ./config.json
## Le serveur supporte les requêtes :
- PUT /account > créer compte
- POST /account > voir le compte
