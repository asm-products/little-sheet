# Sheetsh

<a href="https://assembly.com/little-sheet/bounties"><img src="https://asm-badger.herokuapp.com/little-sheet/badges/tasks.svg" height="24px" alt="Open Tasks" /></a>

## A small sheet you can share

This is a product being built by the Assembly community. You can help push this idea forward by visiting [https://assembly.com/sheetsh](https://assembly.com/sheetsh).

## How to run locally

```
git clone git@github.com:asm-products/sheetsh.git
cd sheetsh
npm install
foreman start -f Procfile.dev
```

**Environment Variables**

You will need a S3 endpoint from which to load your sheets. If you are not going to save, I think you can just type any url, but in any case just use the same as in production:

`S3_ENDPOINT=http://sheetstore.s3-website-us-east-1.amazonaws.com`

If you wanna save you will need the following:

`S3_BUCKET_NAME`, `S3_KEY_ID`, `S3_SECRET` and a correct `S3_ENDPOINT`, of course.

Just put them all in a `.env` file and run with [Foreman](https://toolbelt.heroku.com/).

**To run with a custom build of [react-spreadsheet](https://github.com/asm-products/sheetsh-react-spreadsheet)**

In a separate folder (the parent folder of your github cloned projects, for example):

```
git clone git@github.com:asm-products/sheetsh-react-spreadsheet.git react-spreadsheet
cd react-spreadsheet
npm install
cd ../sheetsh
npm install ../react-spreadsheet/
foreman start -f Procfile.dev
```

### How Assembly Works

Assembly products are like open-source and made with contributions from the community. Assembly handles the boring stuff like hosting, support, financing, legal, etc. Once the product launches we collect the revenue and split the profits amongst the contributors.

Visit [https://assembly.com](https://assembly.com) to learn more.
