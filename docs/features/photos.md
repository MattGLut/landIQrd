# Photo thumbnails

**Status:** Limited. Landlord, contractor, and tenant.

Uploads work. Resized previews depend on an image library that is not installed here.

Job photos and PDFs attach on the job. Images on a job page are the original file, and they display. That is visible on the posted job and on Find work in the [marketplace walkthrough](../walkthrough/README.md).

Avatars, portfolio photos, and older work-order photos still ask the server to resize them. On this machine those tiles render as an empty block.

![Portfolio photos](images/portfolio.png)

The same empty tiles show on the landlord's view of a contractor profile.

![Contractor profile photos](images/contractor-profile.png)

**Where it stops.** Resizing needs libvips or ImageMagick. Neither is on this machine, so those older thumbnails error. The files themselves are stored. Initials stand in for a missing avatar, which is why the directory cards still look complete.
