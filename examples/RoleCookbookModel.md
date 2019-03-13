# Role Cookbook Model

This is intended to show a working example of the "Role Cookbook Model". By 
following the steps outlined below, you can setup a Chef Environment to use this
model and try it out for yourself. Most of this follows the model set forth by
Jeremy Miller @jeremymv2, a colleague of mine @Chef, you can see his original 
Environment Pinning guide here - https://github.com/jeremymv2/env_pinning.

## What the heck is the "Role Cookbook Model" anyways?

The Role Cookbook Model (referred to as the RBM from here) has been referred to 
as a few different things overthe years. It's been called the "Application" 
cookbook model, "Environment" model, and probably some other things. I thin the 
"Role" model is the best namefor this because it just makes sense, you'll see what 
I mean when you read on.

### Key Concepts

* **Limited Blast Radius** - The RBM helps to ensure that changes you make to a
system, or group of systems, is limited to the _intended_ target(s). 
* **Iterate & Fail Often** - When you're blast radius is large, it makes it hard
to fail often, because failing means a bunch of things get broken. In true (here
come some fun DevOps~ words) DevOps fashion, it helps you to be more agile, by
allowing you to target smaller groups of systems in a more controlled manner.
And helps you fix problems in lower environments more quickly.
* **Appropriately Scoped** - The RBM pattern should typically follow your 
organizational pattern, meaning the scope of your orgs, environments and roles
should generally line up with the teams that actually touch the infra and apps
that live within them.
* **Scaleable** - This pattern is scaleable because it is repeatable and 
efficient. It lends itself to the practice of starting small, iterating, then
repeating with other targets. It also allows for complete autonomy within 
environments, for example, the ability to have multiple roles within an 
environment and make changes to them without affecting each other.

### A Simplified View of the Role Cookbook Model

The image below shows a simplified view of the Role Cookbook ecosystem, along
with the steps needed to update a Role Cookbook and publish it to your
environment. You'll notice the roles end in `_g`, that means "Green", we'll dive into that later as we discuss Blue/Green deployment scenarios.

![Role Cookbook Update Process](/images/role_cb_update_process_2.png)

1. A new version of the `openssl` cookbook has become available in
the community Chef Supermarket. The first step is to update the `metadata.rb` of
the Application Cookbook, in this case `web_backend_cb`. Also, as part of this 
step, you would bump the version of the `web_backend_cb` to a higher version.
2. The next step is to update your Role Cookbook with the new version of the
application cookbook you just bumped. Again, in doing so, you will in-turn bump
the version of the Role Cookbook.
3. The final step is to "flip the switch" on the Environment 'cookbook_versions'
pinnings. Once you do this, and push the Environment `.json` up to the Chef
Server, the changes will take affect.

Notice in the above model, the "blast radius" is limited to the `web_backend_g`
role _only_. This ensures that the changes we are making are only going to be
applied to the nodes that have been assigned that role.

### ... Now, one might say: "but, this doesn't stop unintentional changes to other nodes!"

And that is a very true statement! It doesn't, unless this process is applied to
every cookbook you and your team develop. By setting the environment pin to only
care about the Role Cookbook version, **you're trusting that pinning will be 
handled in subsequent cookbooks**. There are some simple methods that can be 
done to automate this process, and even reject uploading a cookbook to the Chef 
Server unless it has dependency versions defined.

## Planning For the Role Cookbook Model

Regardless of where you're starting from, I recommend setting up a [greenfield](https://en.wikipedia.org/wiki/Greenfield_project)
for development and testing of this newR method. I also recommend not attempting 
to migrate existing Chef environments within themselves, but rather, when
possible, create a new environment to move things into. This will give you a 
clean, clear path to _done_, and also prevent you from muddying the waters by
mixing new with old practices.

### Here are some practical steps you should take while planning for the Role Cookbook Model

1. **Understand your environment**: Most organizations have a varied technical
footprint. This footprint includes many applications that perform various duties
in the lifecycle of the applications the organization supports. It also often
includes apps designated as "legacy", and apps dedicated as "next-gen", and of
course, all of the middleware, databases and infrastructure to support them. As
an organization, you should be able to create a diagram that shows all of your
apps, and how they connect to everything else at the very least. If you can do
that, _and_ also draw lines of delineation by function, responsibility and 
frequency of change, then you are in a good position to continue.
1. **Start small**: Once you have a good understanding of your envioronment, 
find a small, but impactful application stack to move into this model. The idea
is to get it working _reallllllly_ well with this small slice of your estate 
first before moving other pieces into this model. 
1. **Iterate frequently**: 
1. 
