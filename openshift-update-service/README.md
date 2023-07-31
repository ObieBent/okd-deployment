Apres avoir déployé l'update service, vous devez modifier le déploiement pour intégrer la CA d'EDF pour qu'il puisse interagir avec S3 apres son démarrage.

Mettez d'abord l'operator à 0 replicas pour pouvoir modifier les ressources :

```sh
 oc scale -n openshift-update-servce deployment/updateservice-operator --replicas=0
 
```