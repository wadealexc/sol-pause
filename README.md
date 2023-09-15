## sol-pause

**This library has not been audited, tested, or even finished.**

`sol-pause` makes it easy to implement a catch-all "panic button" for use during incident response.

You should use something like `sol-pause` if: 
* you intend to have pausable contracts in production
* you want to the option to remove the "pausability" of your contracts once you feel more confident
* you're not sure how to configure "pausability" alongside the other roles/permissions your system has
* you want a solution to all of this that doesn't add much complexity

### How Does it Work?

Pausable contracts inherit from `PausableContract` and may be paused (or unpaused) by the `PauseController`. `PausableContract` is a minimal wrapper around OpenZeppelin's `Pausable`, and works exactly the same way: when paused, any methods protected by the `whenNotPaused` modifier are locked, preventing access/state changes until unpaused.

The `PauseController` is deployed as a singleton and configured with a list of pausable contracts. 
* `PauseController.pauseAll()` iterates over this list and calls `pause()` on each
* `PauseController.unpauseAll()` calls `unpause()` on each

### Why Do I Want This?

The main feature is in the access control used in `PauseController`. There are two levels of access:
* Pausers can call `pauseAll()` - that's it.
* The Owner can call `unpauseAll()`, as well as:
    * add/remove Pausers
    * add/remove pausable contracts
    * (optional) upgrade the `PauseController`
    * (optional) burn/revoke the `PauseController`, removing the ability to pause/unpause contracts

 This separation of roles/access is meant to facilitate incident response by making it safer to provide multiple people with the ability to quickly `pauseAll()`, while not giving them undue amounts of access. 
 
 Pausers can only do one thing: pause the system. If their keys are lost or stolen, the Owner can always be used to remove their access and unpause the system if needed. Pausers are intended to be EOAs held by a handful of people (e.g. employees), whereas the Owner is intended to be held more securely - i.e. a multisig.

 ### On Pausability

Pausability is expected to be used in tandem with other ownable-type controls, including proxy upgradability Pausability is a tool that can be used to support both complex systems and contract upgrades.