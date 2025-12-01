
## SUJET – Vues matérialisées (Boutique en ligne)

### Contexte

Tu travailles pour une **petite boutique en ligne** qui vend des produits high-tech et accessoires.
On souhaite analyser :

* le **montant des commandes**,
* les **ventes par jour**,
* les **clients les plus rentables**.

Les données sont réparties comme suit :

* `customers` : informations clients,
* `products` : catalogue produits,
* `orders` : commandes,
* `order_items` : lignes de commande.

Ton objectif est de mettre en place des **vues** et **vues matérialisées** adaptées à des besoins de reporting, en t’appuyant sur les concepts vus en cours (vues classiques, vues matérialisées, index, rafraîchissement).

---

### 0. Préparation : schéma et données

Exécute d’abord le script suivant :

```sql
-- Nettoyage préalable
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- =========================
-- TABLE : customers
-- =========================
CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    full_name     TEXT        NOT NULL,
    city          TEXT        NOT NULL,
    created_at    DATE        NOT NULL
);

INSERT INTO customers (customer_id, full_name, city, created_at) VALUES
    (1, 'Alice Martin',    'Lille',   DATE '2024-01-10'),
    (2, 'Bruno Dubois',    'Paris',   DATE '2024-02-05'),
    (3, 'Chloé Petit',     'Lyon',    DATE '2024-03-12'),
    (4, 'David Leroy',     'Lille',   DATE '2024-04-01');

-- =========================
-- TABLE : products
-- =========================
CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    name         TEXT        NOT NULL,
    category     TEXT        NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL
);

INSERT INTO products (product_id, name, category, unit_price) VALUES
    (1, 'Clavier mécanique',  'Informatique', 79.90),
    (2, 'Souris gamer',       'Informatique', 49.90),
    (3, 'Casque audio',       'Audio',        89.00),
    (4, 'Tapis de souris',    'Accessoires',  19.90);

-- =========================
-- TABLE : orders
-- =========================
CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date   DATE    NOT NULL,
    status       TEXT    NOT NULL   -- 'PENDING', 'COMPLETED', 'CANCELLED'
);

INSERT INTO orders (order_id, customer_id, order_date, status) VALUES
    (1, 1, DATE '2024-05-01', 'COMPLETED'),
    (2, 1, DATE '2024-05-02', 'COMPLETED'),
    (3, 2, DATE '2024-05-02', 'COMPLETED'),
    (4, 2, DATE '2024-05-03', 'PENDING'),
    (5, 3, DATE '2024-05-03', 'COMPLETED'),
    (6, 4, DATE '2024-05-04', 'CANCELLED');

-- =========================
-- TABLE : order_items
-- =========================
CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       INTEGER NOT NULL REFERENCES orders(order_id),
    product_id     INTEGER NOT NULL REFERENCES products(product_id),
    quantity       INTEGER NOT NULL,
    unit_price     NUMERIC(10,2) NOT NULL
);

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 1, 79.90),
    (2, 1, 4, 2, 19.90),
    (3, 2, 2, 1, 49.90),
    (4, 2, 4, 1, 19.90),
    (5, 3, 3, 1, 89.00),
    (6, 5, 1, 2, 79.90),
    (7, 5, 2, 1, 49.90);
```

---

### 1. Synthèse des commandes

L’équipe métier souhaite disposer d’une vue qui centralise, pour chaque commande :

* les informations de base de la commande (client, date, statut),
* le **montant total** de la commande.

1. Mettre en place une vue adaptée à ce besoin à partir des tables existantes.
2. Exploiter cette vue pour obtenir la liste des commandes **complétées**, avec leurs montants, classées par date puis par identifiant de commande.

---

### 2. Statistiques de ventes par jour

Le service de reporting a besoin d’un **tableau de bord quotidien** indiquant, pour chaque jour :

* le nombre de **commandes complétées**,
* le **chiffre d’affaires total** de ces commandes.

Pour optimiser les performances, ce tableau de bord doit être construit à partir d’une **vue matérialisée** basée sur les données des commandes.

1. Mettre en place une vue matérialisée qui fournit ces statistiques quotidiennes.
2. Interroger cette vue pour afficher la totalité des jours connus, classés par date.
3. Interroger cette même vue pour obtenir uniquement les jours dont le chiffre d’affaires est **supérieur ou égal à 200**.

---

### 3. Clients les plus rentables

La direction souhaite identifier les clients les plus intéressants commercialement, en se basant uniquement sur les **commandes complétées** :

Pour chaque client, on veut connaître :

* le nombre de commandes complétées,
* le chiffre d’affaires total associé.

1. Mettre en place une vue matérialisée qui regroupe ces informations par client.
2. Exploiter cette vue pour afficher la liste des clients, classés du plus gros chiffre d’affaires au plus faible.
3. Exploiter cette vue pour afficher uniquement les clients ayant passé **au moins deux** commandes complétées.

---

### 4. Optimisation via index

Certaines requêtes sont particulièrement fréquentes :

* filtrer ou trier les statistiques **par date**,
* interroger souvent les clients par **chiffre d’affaires total**.

1. Proposer un ou plusieurs index pertinents sur les vues matérialisées précédentes afin d’optimiser ces usages.
2. Justifier brièvement, pour chaque index, le type de requête qu’il permet d’accélérer.

---

### 5. Données à jour vs vues matérialisées

On simule maintenant l’arrivée de nouvelles données dans le système :

Une nouvelle commande complétée est enregistrée pour le client 2 :

```sql
INSERT INTO orders (order_id, customer_id, order_date, status)
VALUES (7, 2, DATE '2024-05-04', 'COMPLETED');

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
    (8, 7, 3, 1, 89.00),
    (9, 7, 4, 1, 19.90);
```

1. Vérifier, à l’aide de la vue classique mise en place à la question 1, que cette nouvelle commande est bien prise en compte.
2. Vérifier, à l’aide de la vue matérialisée de statistiques quotidiennes, si les données reflètent ou non cette nouvelle commande.
3. Mettre à jour la vue matérialisée de statistiques quotidiennes pour qu’elle reflète l’état actuel des données.
4. Refaire la vérification et expliquer (en quelques mots, par commentaire ou à l’oral) la différence de comportement entre la vue classique et la vue matérialisée.