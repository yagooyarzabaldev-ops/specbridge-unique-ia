# Do Not Touch

## Protected by Default

Agents must not modify or request access to the following unless the active policy and execution contract explicitly allow it:

- `.env`
- `.env.*`
- secrets
- tokens
- private keys
- production configuration
- billing configuration
- authentication security
- authorization security
- CI/CD security controls
- destructive database operations

## Foundation Phase Restriction

During foundation phase, agents must not add product implementation code.

Allowed work during foundation phase:

- documentation
- specs
- policy files
- context package files
- repository governance files

Blocked work during foundation phase:

- application source code
- package installation
- runtime framework setup
- deployment automation
- database schema implementation
- external service integration
