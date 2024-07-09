const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function fetchPlayerSalaries() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  try {
    await page.goto('https://www.basketball-reference.com/contracts/players.html', { waitUntil: 'networkidle2', timeout: 60000 });
    await page.waitForSelector('table#player-contracts', { timeout: 60000 });

    const players = await page.evaluate(() => {
      const rows = Array.from(document.querySelectorAll('table#player-contracts tbody tr'));
      return rows.map(row => {
        const cells = row.querySelectorAll('td');
        if (cells.length < 5) return null; // Skip rows that don't have enough data
        const name = cells[0].innerText.trim();
        const team = cells[1].innerText.trim();
        const salary2024 = cells[2].innerText.trim().replace(/\$|,/g, ''); // Remove both $ and ,
        return {
          name: name,
          team: team,
          grossSalary: parseFloat(salary2024),
        };
      }).filter(player => player !== null); // Filter out null values
    });

    await browser.close();
    return players;
  } catch (error) {
    console.error("Error fetching player salaries:", error);
    await browser.close();
    throw error;
  }
}

fetchPlayerSalaries().then(players => {
  if (players && players.length > 0) {
    const csvContent = 'Name,Team,GrossSalary\n' + players.map(p => `${p.name},${p.team},${p.grossSalary}`).join('\n');
    fs.writeFileSync(path.join(__dirname, 'nba_salaries.csv'), csvContent);
    console.log('Data saved to nba_salaries.csv');
  } else {
    console.log('No data found or failed to fetch data.');
  }
}).catch(error => {
  console.error('Failed to save data:', error);
});
