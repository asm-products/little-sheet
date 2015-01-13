# Sheetsh

<a href="https://assembly.com/little-sheet/bounties"><img src="https://asm-badger.herokuapp.com/little-sheet/badges/tasks.svg" height="24px" alt="Open Tasks" /></a>

## A small sheet you can share

This is a product being built by the Assembly community. You can help push this idea forward by visiting [https://assembly.com/little-sheet](https://assembly.com/little-sheet).

## How to run locally

```
git clone git@github.com:asm-products/little-sheet.git
cd little-sheet
npm install
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
foreman start -f Procfile.dev
```

*This will run it with the react-spreadsheet component loaded from npm. If you wanna use your own copy of react-spreadsheet, continue reading.*


### Environment Variables

If you don't want to save the sheets, you don't need any environment variable, but if you do, you will need the following:

`S3_KEY_ID`, `S3_SECRET`, `S3_BUCKET_NAME` and a corresponding `S3_ENDPOINT`.

You can get a view-only access to the current database of sheets by having only

`S3_ENDPOINT=http://sheetstore.s3-website-us-east-1.amazonaws.com`

Just put them all in a `.env` file and run with [Foreman](https://toolbelt.heroku.com/).

### To run with a custom build of [react-spreadsheet](https://github.com/asm-products/little-sheet-react-spreadsheet)

In a separate folder (the parent folder of your github cloned projects, for example):

```
git clone git@github.com:asm-products/little-sheet-react-spreadsheet.git react-spreadsheet
cd react-spreadsheet
npm install
cd ../little-sheet
npm install ../react-spreadsheet/
foreman start -f Procfile.dev
```

### How Assembly Works

Assembly products are like open-source and made with contributions from the community. Assembly handles the boring stuff like hosting, support, financing, legal, etc. Once the product launches we collect the revenue and split the profits amongst the contributors.

Visit [https://assembly.com](https://assembly.com) to learn more.
