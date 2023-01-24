# RMPproject

This project was all about using data from the RateMyProfessor website to gain insights about the different colleges at San Jose State University.

Shortly after attempting to use Beautiful Soup to scrape data from the Ratemyprofessor.com website, I realized that the website was a dynamically loaded
JavaScript Website. This meant I had to use Selenium to load all of the webpage before scraping.

In the Jupyter Notebook, I used Selenium automation to close the initial webpage advertisement and "load more" until all the professors were loaded. Then,
Selenium scraped all of this professor data. I put this into a Pandas DataFrame, exported the CSV, and then moved to MySQL.

In MySQL, I cleaned the data by removing unecessary rows and filling null values when posssible. After cleaning the data, I did some light data 
exploration by making tables that showed some interesting differences between SJSU colleges.

I exported some of these new tables into Tableau and made a dashboard to visualize the most interesting insights that I came accross. 
