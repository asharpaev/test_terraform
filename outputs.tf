output "master_private_address" {
value = "${aws_instance.master.private_ip}"
}

output "worker_token" {
value = "${data.external.swarm_tokens.result["worker"]}"
}
output "manager_token" {
value = "${data.external.swarm_tokens.result["manager"]}"
}
