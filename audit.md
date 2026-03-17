# Discussion 24 février 2026
- Retirer les choses de firebases

## Reverse proxy
- 34210 => Port ouvert
- Port SSH à mettre à mettre à jour (version sensible)
- Security headers 
    - Est-ce que CORS est activé?
    - Apprendre sur HSTS?

## Frontend
- Mot de passe ne devrait pas empêcher de se connecter sans respecter la politique (pour éviter brute force)
    - Valider backend en temps constant
- Ne pas mettre "mot de passe incorrect", mais plutôt "identifiant ou mot de passe incorrect" pour éviter de donner des indices aux attaquants
- Retour de l'erreur SQL si nom d'utilisateur est trop long (>40 caractères)
    - Ne pas retourner l'erreur technique au client (retourner erreur interne)
- Google maps API key restriction (white listing?)

## Backend
- Retirer le endpoint bug_report_management
- Bind sur localhost plutôt que 0.0.0.0
- Rate limit pour le websocket
- Size limit pour les requêtes (pour éviter les attaques de type DoS) (https et websocket)
- Changer mot de passe "devpassword"

## Collectif HUB
- Demander où sont hébergés les données
- Demander pour créer un compte pour tester le backend
- Demander pour SSH sécurisé
