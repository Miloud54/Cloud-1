# Cloud-1 — Notes de projet

## Plan étape par étape

1. ✅ Théorie
2. ✅ Provider (AWS), compte, alerte budget, clé SSH, instance Ubuntu 22.04 + security group 22/80/443
3. ✅ Ansible en local, inventory, `ansible all -m ping`
4. ✅ Rôle `common` : paquets, swap, mises à jour
5. ✅ Rôle `docker` : Docker Engine + plugin compose, service activé au boot
6. ✅ Rôle `firewall` : UFW (22/80/443)
7. ⏳ Rôle `app` : compose, `.env` depuis le Vault, `docker compose up`
8. nginx : routage `/` et `/phpmyadmin`, puis TLS (DuckDNS + Let's Encrypt)
9. Tests : idempotence (2ᵉ run = `changed=0`), reboot (site + données intacts), scan de ports (`nmap`), 2 serveurs en parallèle
10. Doc + nettoyage des ressources cloud

---

## Étape 7 : le rôle `app`

### Décisions d'architecture

| Sujet | Choix retenu | Pourquoi | Alternatives écartées |
|---|---|---|---|
| **Images Docker** | Images officielles : `mariadb`, `wordpress:fpm`, `phpmyadmin:fpm`, `nginx` + un conteneur `wordpress:cli` éphémère qui installe WordPress automatiquement | Pas de build sur le t3.micro (1 Go de RAM), mises à jour de sécurité gérées par les mainteneurs, moins de code | *Hybride* : image WordPress perso d'Inception, build sur le serveur. *Tout Inception* : build lourd, plus de code à maintenir |
| **Secrets** | Ansible Vault : `group_vars/all/vault.yml` chiffré en AES256 et versionné. Mot de passe dans `.vault_pass`, ignoré par Git | Le dépôt suffit pour déployer, et rien n'est en clair | *Fichiers locaux ignorés* : rien n'est chiffré, et le dépôt seul ne suffit pas |
| **Routage / TLS** | Par chemin + DuckDNS : `https://<nom>.duckdns.org/` → WordPress, `/phpmyadmin` → phpMyAdmin. Un seul certificat Let's Encrypt | Simple, avec un certificat valide | *Sous-domaines* : certificat multi-domaines. *Auto-signé seul* : alerte navigateur |

### Sous-étapes

- **7a** : secrets et variables (Vault + domaine DuckDNS)
- **7b** : la stack (compose, nginx, installation auto de WordPress, phpMyAdmin), d'abord avec un certificat auto-signé
- **7c** : TLS Let's Encrypt

---

## 7a.1 : Obtenir un domaine DuckDNS

1. Aller sur <https://www.duckdns.org> et se connecter (avec GitHub par exemple).
2. Créer un sous-domaine, par exemple `edidier-cloud1`, ce qui donne `edidier-cloud1.duckdns.org`.
3. Dans *current ip*, mettre l'IP publique de l'instance, puis cliquer sur *update ip*.
4. Noter le **token** affiché en haut de la page. **C'est un secret** : il permet de modifier le domaine. Il va dans le Vault.

Vérification :

```bash
getent hosts edidier-cloud1.duckdns.org    # doit renvoyer l'IP de l'instance
```

> L'IP de l'instance change à chaque *Stop/Start*. Plus tard, Ansible mettra DuckDNS à jour automatiquement avec le token.

## 7a.2 : Le mot de passe du Vault

```bash
openssl rand -hex 32 > .vault_pass
chmod 600 .vault_pass
git check-ignore .vault_pass        # doit afficher ".vault_pass"
```

Ajouter dans la section `[defaults]` de `ansible.cfg` :

```ini
vault_password_file = .vault_pass
```

> ⚠️ **Sauvegarder le contenu de `.vault_pass` ailleurs**, par exemple dans un gestionnaire de mots de passe. Si ce fichier est perdu, le Vault devient illisible.

## 7a.3 : Créer le Vault

Générer 3 mots de passe. On utilise `-hex` pour éviter `/`, `+` et `=`, qui posent des problèmes d'échappement dans les `.env` :

```bash
openssl rand -hex 20    # à lancer 3 fois
```

Créer le Vault :

```bash
ansible-vault create group_vars/all/vault.yml
```

Contenu à saisir dans l'éditeur qui s'ouvre :

```yaml
---
vault_app_db_root_password: "<mot de passe 1>"
vault_app_db_password: "<mot de passe 2>"
vault_app_wp_admin_password: "<mot de passe 3>"
vault_app_wp_admin_email: "<email>"
vault_duckdns_token: "<token DuckDNS>"
```

Vérification :

```bash
head -1 group_vars/all/vault.yml              # $ANSIBLE_VAULT;1.1;AES256
ansible-vault view group_vars/all/vault.yml   # contenu en clair
```

> L'email n'est pas un secret, mais il est dans le Vault pour ne pas publier une donnée personnelle dans un dépôt potentiellement public.

## 7a.4 : Les variables non secrètes

`group_vars/all/vars.yml` :

```yaml
---
app_dir: /opt/cloud1

app_db_name: wordpress
app_db_user: wpuser
app_db_password: "{{ vault_app_db_password }}"
app_db_root_password: "{{ vault_app_db_root_password }}"

app_wp_title: Cloud-1
app_wp_admin_user: <nom d'admin>
app_wp_admin_password: "{{ vault_app_wp_admin_password }}"
app_wp_admin_email: "{{ vault_app_wp_admin_email }}"

app_duckdns_token: "{{ vault_duckdns_token }}"
```

> **Convention de la double variable** : les secrets s'appellent `vault_*` dans `vault.yml`. Les rôles utilisent des variables `app_*` définies dans `vars.yml`, qui pointent vers les `vault_*`. Un `grep app_db_password` montre ainsi où la variable est définie, sans déchiffrer le Vault.

## 7a.5 : Un domaine par serveur, dans l'inventory

Chaque serveur a son propre domaine, ce qui est indispensable pour déployer en parallèle. C'est donc une **variable d'hôte**, dans `inventory/hosts.ini` :

```ini
[cloud1]
cloud1-1 ansible_host=<IP> app_domain=<sous-domaine>.duckdns.org
```

## 7a : Vérification

```bash
ansible all -m debug -a "var=app_domain"
ansible all -m debug -a "var=app_db_user"
ansible all -m debug -a "var=app_db_password"   # en clair = le Vault est bien déchiffré
git status                                       # vault.yml OUI (chiffré), .vault_pass NON
```

> Ne jamais partager la sortie du `debug` sur un mot de passe.
