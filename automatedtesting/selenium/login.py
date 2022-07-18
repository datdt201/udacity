# #!/usr/bin/env python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.common.by import By
import logging
import syslog

logging.basicConfig(
    format='%(asctime)s %(levelname)-8s %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.FileHandler("selenium.log"),
        logging.StreamHandler()
    ])

def log(message):
    syslog.syslog(syslog.LOG_INFO, message)
    logging.info(message)

log('Starting the browser...')
options = ChromeOptions()
options.add_argument("--headless") 
driver = webdriver.Chrome(options=options)

log('Start browser successfully. Opening login page...')
driver.get('https://www.saucedemo.com/')
title = driver.title
assert title == "Swag Labs"

driver.implicitly_wait(0.5)
log('Open login page successfully. Logging in...')
username = "standard_user"
password = "secret_sauce"
username_textbox = driver.find_element(by=By.ID, value="user-name")
password_textbox = driver.find_element(by=By.ID, value="password")
username_textbox.send_keys(username)
password_textbox.send_keys(password)
assert username_textbox.get_attribute("value") == username
assert password_textbox.get_attribute("value") == password
driver.find_element(by=By.ID, value="login-button").click()

driver.implicitly_wait(0.5)
log('Login successfully. Adding all the products to the cart...')
inventory_items = driver.find_elements(by=By.CLASS_NAME, value="inventory_item")
log('Found ' + str(len(inventory_items)) + ' items in inventory')
for item in inventory_items:
    item.find_element(by=By.CLASS_NAME, value="btn_inventory").click()
    log('Added ' + item.find_element(by=By.CLASS_NAME, value="inventory_item_name").text)

log('Add products successfully. Opening the cart...')
driver.find_element(by=By.CLASS_NAME, value="shopping_cart_link").click()

driver.implicitly_wait(0.5)
cart_items = driver.find_elements(by=By.CLASS_NAME, value="cart_item")
assert len(inventory_items) == len(cart_items)

log('Open cart successfully. Clearing the cart...')
log('Found ' + str(len(cart_items)) + ' items in cart')
for item in cart_items:
    log('Removed ' + item.find_element(by=By.CLASS_NAME, value="inventory_item_name").text)
    item.find_element(by=By.CLASS_NAME, value="cart_button").click()

assert len(driver.find_elements(by=By.CLASS_NAME, value="cart_item")) == 0
log('Clear cart successfully.')