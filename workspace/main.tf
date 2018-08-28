resource "tfe_workspace" "ws" {
  name = "${var.ws_name}"
  organization = "${var.organization}"
  vcs_repo = {
      identifier = "${var.github_org}/${var.deploy_vault_repo}"
      branch = "${var.deploy_image_repo_branch}"
      oauth_token_id = "${var.oauth_token}"
      ingress_submodules = true
  }
}





