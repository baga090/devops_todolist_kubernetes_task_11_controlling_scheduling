# Advanced Kubernetes Scheduling (Taints, Tolerations, Affinity)

## 1. How to deploy all resources
Run the provided bootstrap script. It will spin up a multi-node cluster, apply the `NoSchedule` taint to nodes designated for MySQL, and deploy all workloads using advanced scheduling rules.
```bash
sh bootstrap.sh
```

## 2. Architecture & Best Practices Rationale
The scheduling logic implemented here guarantees workload isolation and high availability:
* **Taints & Tolerations (Isolation):** MySQL nodes are tainted with `app=mysql:NoSchedule`. This acts as a security guard, ensuring no general application workloads (like our Django app) can run on database hardware. The MySQL StatefulSet has the corresponding `Toleration` to bypass this.
* **Affinity Rules:**
  * The MySQL StatefulSet uses a `requiredDuringSchedulingIgnoredDuringExecution` Node Affinity rule to strictly bind it to `app=mysql` labeled nodes.
  * The Django app uses a `preferredDuringSchedulingIgnoredDuringExecution` (Soft) rule for `app=todoapp` nodes, allowing the scheduler flexibility if those preferred nodes become unavailable.
* **Production Context (Topology Spread Constraints):** While `PodAntiAffinity` is used here to ensure database replicas don't share the same node, in modern large-scale production environments, we often transition to `TopologySpreadConstraints`. This prevents scheduling deadlocks (where pods are stuck `Pending` because no more empty nodes exist) by distributing pods evenly across available fault domains (zones/nodes) rather than strictly forbidding co-location.

## 3. How to validate the changes

### Step A: Verify Node Taints and Labels
Check that the nodes labeled `app=mysql` successfully received the `NoSchedule` taint:
```bash
kubectl get nodes -l app=mysql
kubectl describe nodes -l app=mysql | grep Taints
```

### Step B: Validate StatefulSet Scheduling (Pod Anti-Affinity)
Our cluster has only 2 nodes labeled `app=mysql`, but the StatefulSet requests 3 replicas. Due to the strict `PodAntiAffinity` rule preventing co-location, the scheduler will intentionally leave the 3rd pod in a `Pending` state.
```bash
kubectl get pods -n mysql -o wide
```
*Expected Output:* `mysql-0` and `mysql-1` will be `Running` on different nodes, while `mysql-2` remains `Pending`. This validates that the Anti-Affinity rule is strictly enforced.

### Step C: Validate Deployment Scheduling
Verify that the ToDo application pods are scheduled on distinct nodes (enforced by Pod Anti-Affinity) and are running on nodes carrying the `app=todoapp` label (as preferred by Node Affinity):
```bash
kubectl get pods -n mateapp -l app=todolist -o wide
```
*Expected Output:* Both deployment pods must be located on different worker nodes.