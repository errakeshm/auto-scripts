const puppeteer = require('puppeteer');
const readline = require('readline');

const MAX_NO_OF_RECORDS = 5;

const r1 = readline.createInterface({
    input: process.stdin,
    output: process.stdout
})

class ImdbDO {
    constructor(title, rating, url) {
        this.title = title;
        this.rating = rating;
        this.url = url;
    }

    getTitle() {
        return this.title;
    }

    getRating() {
        return this.rating;
    }

    getUrl() {
        return this.url;
    }
}


r1.question("Please enter the movie name : ", function (name) {
    if (name == null || name == undefined) {
        console.error('No input supplied');
        process.exit(0);
    }

    getImdbRating(name);

});

function getImdbRating(name) {
    puppeteer.launch({ headless: true}).then(async browser => {
        try {
            const page = await browser.newPage();
            await page.setRequestInterception(true);

            //to make it faster
            page.on('request', function (request) {
                if (request.resourceType() === 'image' || request.resourceType() === 'stylesheet' || request.resourceType() === 'font') {
                    request.abort();
                } else {
                    request.continue();
                }

            });

            await page.setViewport({ width: 1280, height: 800 });
            await page.goto("https://imdb.com/", { waitUntil: 'load', timeout: 0 });
            await page.waitForSelector('.nav-search__search-input-container');
            await page.focus('.nav-search__search-input-container .imdb-header-search__input');
            await page.keyboard.type(name);
            await page.click('.nav-search__search-submit');
            await page.waitForSelector('.article');


            let articleNodesList = await page.evaluate(() => Array.from(document.querySelectorAll('div.findSection')[0].querySelectorAll('.findList tr a'), e => e.href))
            articleNodesList = articleNodesList
                .filter(href => href.indexOf('/title/') != -1)
                .map(href => href.replace('https://www.imdb.com', ''));
            articleNodesList = [...new Set(articleNodesList)];

            let size = articleNodesList.length;
            size = size > MAX_NO_OF_RECORDS ? MAX_NO_OF_RECORDS : size;
            let imdbMovieList = [];
            for (let i = 0; i < size; i++) {
                await page.click('.findList tr a[href="' + articleNodesList[i] + '"]')
                await page.waitForNavigation({ waitUntil: 'load', timeout: 0 });
                await page.waitForSelector('.title_block .titleBar');

                let movieName = await page.evaluate(() => document.querySelector('.title_block .titleBar .title_wrapper h1').innerText, e => e)
                let movieRating = await page.evaluate(() => document.querySelector('.title_block .title_bar_wrapper .ratings_wrapper .ratingValue').innerText, e => e)

                let imdb = new ImdbDO(movieName, movieRating, 'https://www.imdb.com' + articleNodesList[i]);
                imdbMovieList.push(imdb);
                await page.goBack();
                await page.waitForSelector('.article');
            }
            console.log('####### RATINGS #########');
            imdbMovieList.forEach(movie => { console.log(movie.getTitle() + " - " + movie.getRating() + ' [ ' + movie.getUrl() + ' ] ') });
            console.log('#########################')
        } catch (e) {
            console.error('ERROR OCCURED : ' + e.message);
            await browser.close();
            process.exit();
        } finally {
            await browser.close();
            process.exit();
        }
    })
}