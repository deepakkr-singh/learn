# ============================================================================
# USE EXISTING STEP FUNCTIONS RESOURCES
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when you need to reference existing Step Functions state machines
# created outside of this module (e.g., by Platform Team).
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. State Machine Information:
#    - State machine name or ARN
#    - State machine type (STANDARD or EXPRESS)
#    - Execution role ARN
#
# 2. Permissions:
#    - Can I start executions?
#    - Can I view execution history?
#
# 3. Integration Details:
#    - What services does it integrate with?
#    - Required input format
#    - Expected output format
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for state machine name/ARN
# 2. Use data sources below to fetch existing state machine
# 3. Reference outputs in your configurations
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING STATE MACHINES
# ----------------------------------------------------------------------------

# Fetch state machine by name
data "aws_sfn_state_machine" "by_name" {
  count = var.existing_state_machine_name != "" ? 1 : 0

  name = var.existing_state_machine_name
}

# Fetch state machine by ARN (if you have ARN directly)
data "aws_sfn_state_machine" "by_arn" {
  count = var.existing_state_machine_arn != "" ? 1 : 0

  arn = var.existing_state_machine_arn
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING IAM ROLE
# ----------------------------------------------------------------------------

data "aws_iam_role" "existing" {
  count = var.existing_iam_role_name != "" ? 1 : 0

  name = var.existing_iam_role_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "existing_state_machine_arn" {
  description = "ARN of existing state machine"
  value = var.existing_state_machine_name != "" ? data.aws_sfn_state_machine.by_name[0].arn : (
    var.existing_state_machine_arn != "" ? data.aws_sfn_state_machine.by_arn[0].arn : null
  )
}

output "existing_state_machine_name" {
  description = "Name of existing state machine"
  value = var.existing_state_machine_name != "" ? data.aws_sfn_state_machine.by_name[0].name : (
    var.existing_state_machine_arn != "" ? data.aws_sfn_state_machine.by_arn[0].name : null
  )
}

output "existing_state_machine_creation_date" {
  description = "Creation date of existing state machine"
  value = var.existing_state_machine_name != "" ? data.aws_sfn_state_machine.by_name[0].creation_date : (
    var.existing_state_machine_arn != "" ? data.aws_sfn_state_machine.by_arn[0].creation_date : null
  )
}

output "existing_state_machine_role_arn" {
  description = "IAM role ARN of existing state machine"
  value = var.existing_state_machine_name != "" ? data.aws_sfn_state_machine.by_name[0].role_arn : (
    var.existing_state_machine_arn != "" ? data.aws_sfn_state_machine.by_arn[0].role_arn : null
  )
}

output "existing_state_machine_type" {
  description = "Type of existing state machine (STANDARD or EXPRESS)"
  value = var.existing_state_machine_name != "" ? data.aws_sfn_state_machine.by_name[0].type : (
    var.existing_state_machine_arn != "" ? data.aws_sfn_state_machine.by_arn[0].type : null
  )
}

output "existing_iam_role_arn" {
  description = "ARN of existing IAM role"
  value       = var.existing_iam_role_name != "" ? data.aws_iam_role.existing[0].arn : null
}

output "existing_resources_summary" {
  description = "Summary of existing Step Functions resources"
  value = {
    state_machine = var.existing_state_machine_name != "" ? {
      name         = data.aws_sfn_state_machine.by_name[0].name
      arn          = data.aws_sfn_state_machine.by_name[0].arn
      type         = data.aws_sfn_state_machine.by_name[0].type
      role_arn     = data.aws_sfn_state_machine.by_name[0].role_arn
      created_date = data.aws_sfn_state_machine.by_name[0].creation_date
    } : (
      var.existing_state_machine_arn != "" ? {
        name         = data.aws_sfn_state_machine.by_arn[0].name
        arn          = data.aws_sfn_state_machine.by_arn[0].arn
        type         = data.aws_sfn_state_machine.by_arn[0].type
        role_arn     = data.aws_sfn_state_machine.by_arn[0].role_arn
        created_date = data.aws_sfn_state_machine.by_arn[0].creation_date
      } : "not provided"
    )

    iam_role = var.existing_iam_role_name != "" ? data.aws_iam_role.existing[0].arn : "not provided"
  }
}
